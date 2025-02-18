# frozen_string_literal: true

module Import
  class ReassignPlaceholderUserRecordsService
    MEMBER_SELECT_BATCH_SIZE = 100
    MEMBER_DELETE_BATCH_SIZE = 1_000
    GROUP_FINDER_MEMBER_RELATIONS = %i[direct inherited shared_from_groups].freeze
    PROJECT_FINDER_MEMBER_RELATIONS = %i[direct inherited invited_groups shared_into_ancestors].freeze
    RELATION_BATCH_SLEEP = 5 # TODO: Remove with https://gitlab.com/gitlab-org/gitlab/-/issues/504995
    DATABASE_TABLE_HEALTH_INDICATORS = [Gitlab::Database::HealthStatus::Indicators::AutovacuumActiveOnTable].freeze
    GLOBAL_DATABASE_HEALTH_INDICATORS = [
      Gitlab::Database::HealthStatus::Indicators::WriteAheadLog,
      Gitlab::Database::HealthStatus::Indicators::PatroniApdex
    ].freeze

    DatabaseHealthStatusChecker = Struct.new(:id, :job_class_name)
    DatabaseHealthError = Class.new(StandardError)

    def initialize(import_source_user)
      @import_source_user = import_source_user
      @reassigned_by_user = import_source_user.reassigned_by_user
      @unavailable_tables = []
      @project_membership_created = false
    end

    def execute
      return unless import_source_user.reassignment_in_progress?

      warn_about_any_risky_reassignments

      log_warn('Reassigned by user was not found, this may affect membership checks') unless reassigned_by_user

      begin
        reassign_placeholder_references

        if placeholder_memberships.any?
          create_memberships
          delete_placeholder_memberships
        end

      rescue DatabaseHealthError => error
        log_warn("#{error.message}. Rescheduling reassignment")

        return reschedule_reassignment_response
      end

      UserProjectAccessChangedService.new(import_source_user.reassign_to_user_id).execute if project_membership_created?

      import_source_user.complete!

      ServiceResponse.success(
        message: s_('Import|Placeholder user record reassignment complete'),
        payload: import_source_user
      )
    end

    private

    attr_accessor :import_source_user, :reassigned_by_user, :unavailable_tables

    def warn_about_any_risky_reassignments
      warn_about_reassign_to_admin if import_source_user.reassign_to_user.admin? # rubocop:disable Cop/UserAdmin -- Not authentication related
      warn_about_different_contributor_and_importer_hosts if contributor_and_importer_hosts_different?
    end

    def warn_about_different_contributor_and_importer_hosts
      warn_about_risky_reassignment(
        "Reassigning contributions to user with different email host from user who triggered the reassignment"
      )
    end

    def warn_about_reassign_to_admin
      warn_about_risky_reassignment("Reassigning contributions to user with admin privileges")
    end

    def warn_about_risky_reassignment(message)
      ::Import::Framework::Logger.warn(
        message: message,
        namespace: import_source_user.namespace.full_path,
        source_hostname: import_source_user.source_hostname,
        source_user_id: import_source_user.id,
        reassign_to_user_id: import_source_user.reassign_to_user_id,
        reassigned_by_user_id: import_source_user.reassigned_by_user_id
      )
    end

    def contributor_and_importer_hosts_different?
      Mail::Address.new(import_source_user.reassign_to_user.email).domain !=
        Mail::Address.new(import_source_user.reassigned_by_user&.email).domain
    end

    def reassign_placeholder_references
      Import::SourceUserPlaceholderReference.model_groups_for_source_user(import_source_user).each do |reference_group|
        Import::SourceUserPlaceholderReference.model_relations_for_source_user_reference(
          model: reference_group.model,
          source_user: import_source_user,
          user_reference_column: reference_group.user_reference_column,
          alias_version: reference_group.alias_version
        ) do |model_relation, placeholder_references|
          if Feature.enabled?(:reassignment_throttling, reassigned_by_user)
            # If table health check fails, skip processing this relation
            # and move on to the next one. We later raise a `DatabaseHealthError` to
            # reschedule the reassignment where the skipped relations can be tried again.
            if db_table_unavailable?(model_relation)
              unavailable_tables << model_relation.table_name
              next
            end

            db_health_check!
          end

          reassign_placeholder_records_batch(model_relation, placeholder_references)

          # TODO: Remove with https://gitlab.com/gitlab-org/gitlab/-/issues/504995
          Kernel.sleep RELATION_BATCH_SLEEP unless Feature.enabled?(:reassignment_throttling, reassigned_by_user)
        end

      rescue Import::PlaceholderReferences::AliasResolver::MissingAlias => e
        ::Import::Framework::Logger.error(
          message: "#{reference_group.model} is not a model, " \
            "#{reference_group.user_reference_column} cannot be reassigned.",
          error: e.message,
          source_user_id: import_source_user.id
        )
      end

      raise DatabaseHealthError if unavailable_tables.any?
    end

    def reassign_placeholder_records_batch(model_relation, placeholder_references)
      aliased_user_reference_column = placeholder_references.first.aliased_user_reference_column
      model_relation.klass.transaction do
        model_relation.update_all({ aliased_user_reference_column => import_source_user.reassign_to_user_id })
      end
      placeholder_references.delete_all
    rescue ActiveRecord::RecordNotUnique
      placeholder_references.each do |placeholder_reference|
        reassign_placeholder_record(placeholder_reference, aliased_user_reference_column)
      end
    end

    def reassign_placeholder_record(placeholder_reference, user_reference_column)
      placeholder_reference.model_record.update!({ user_reference_column => import_source_user.reassign_to_user_id })
      placeholder_reference.destroy!
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      log_warn('Unable to reassign record, reassigned user is invalid or not unique')
    end

    def create_memberships
      group_ids = import_source_user.namespace.self_and_descendant_ids
      project_ids = import_source_user.namespace.all_project_ids

      placeholder_memberships.each_batch(of: MEMBER_SELECT_BATCH_SIZE) do |relation|
        relation.with_groups.by_group(group_ids).each do |placeholder_membership|
          create_membership(placeholder_membership.group, placeholder_membership)
        end

        relation.with_projects.by_project(project_ids).each do |placeholder_membership|
          create_membership(placeholder_membership.project, placeholder_membership)
        end
      end
    end

    def create_membership(memberable, placeholder_membership)
      existing_membership = find_existing_membership(memberable)

      # If user is a member (direct or inherited) with higher level, skip creating the membership.
      if existing_membership
        if existing_membership.access_level > placeholder_membership.access_level
          log_create_membership_skipped('Existing membership of higher access level found for user, skipping',
            placeholder_membership, existing_membership)

          return
        end

        # There's an outside chance that the user was already given membership manually
        # to this memberable between the time the import finished and the reassignment process began.
        # In this case, we don't override the existing direct membership, we skip creating it.
        if existing_membership.source == memberable
          log_create_membership_skipped(
            'Existing direct membership of lower or equal access level found for user, ' \
              'skipping',
            placeholder_membership, existing_membership)

          return
        end
      end

      member = memberable.members.new(
        user_id: import_source_user.reassign_to_user_id,
        access_level: placeholder_membership.access_level,
        expires_at: placeholder_membership.expires_at,
        created_by: reassigned_by_user,
        importing: true
      )

      member.save!

      @project_membership_created = true if memberable.is_a?(Project)
    rescue ActiveRecord::ActiveRecordError => exception
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
        exception,
        message: 'Unable to create membership',
        placeholder_membership: placeholder_membership.attributes
      )
    end

    def find_existing_membership(memberable)
      if memberable.is_a?(Project)
        existing_project_membership(memberable)
      else
        existing_group_membership(memberable)
      end
    end

    def existing_project_membership(project)
      MembersFinder.new(project, reassigned_by_user)
        .execute(include_relations: PROJECT_FINDER_MEMBER_RELATIONS)
        .find_by_user_id(import_source_user.reassign_to_user_id)
    end

    def existing_group_membership(group)
      GroupMembersFinder.new(group, reassigned_by_user)
        .execute(include_relations: GROUP_FINDER_MEMBER_RELATIONS)
        .find_by_user_id(import_source_user.reassign_to_user_id)
    end

    def delete_placeholder_memberships
      loop do
        delete_count = placeholder_memberships.limit(MEMBER_DELETE_BATCH_SIZE).delete_all

        break if delete_count == 0
      end
    end

    def placeholder_memberships
      Import::Placeholders::Membership.by_source_user(import_source_user)
    end

    def project_membership_created?
      @project_membership_created == true
    end

    def db_table_unavailable?(model)
      health_context = Gitlab::Database::HealthStatus::Context.new(
        DatabaseHealthStatusChecker.new(import_source_user.id, self.class.name),
        nil,
        [model.table_name]
      )

      Gitlab::Database::HealthStatus.evaluate(health_context, DATABASE_TABLE_HEALTH_INDICATORS).any?(&:stop?)
    end

    def db_health_check!
      stop_signal = Rails.cache.fetch("reassign_placeholder_user_records_service_db_check", expires_in: 30.seconds) do
        gitlab_schema = :gitlab_main

        health_context = Gitlab::Database::HealthStatus::Context.new(
          DatabaseHealthStatusChecker.new(import_source_user.id, self.class.name),
          Gitlab::Database.schemas_to_base_models[gitlab_schema].first,
          nil
        )

        Gitlab::Database::HealthStatus
          .evaluate(health_context, GLOBAL_DATABASE_HEALTH_INDICATORS).any?(&:stop?)
      end

      raise DatabaseHealthError, "Database unhealthy" if stop_signal
    end

    def reschedule_reassignment_response
      ServiceResponse.new(
        status: :ok,
        message: s_('Import|Rescheduling placeholder user records reassignment: database health'),
        payload: import_source_user,
        reason: :db_health_check_failed
      )
    end

    def log_create_membership_skipped(message, placeholder_membership, existing_membership)
      log_info(
        message,
        placeholder_membership: placeholder_membership.attributes,
        existing_membership: existing_membership.attributes.slice(
          'id', 'access_level', 'source_id', 'source_type', 'user_id'
        )
      )
    end

    def logger
      Framework::Logger
    end

    def log_info(...)
      logger.info(logger_params(...))
    end

    def log_warn(...)
      logger.warn(logger_params(...))
    end

    def logger_params(message, **params)
      params.merge(
        message: message,
        source_user_id: import_source_user.id
      )
    end
  end
end
