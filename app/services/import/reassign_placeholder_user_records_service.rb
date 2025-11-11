# frozen_string_literal: true

module Import
  class ReassignPlaceholderUserRecordsService
    include Gitlab::InternalEventsTracking

    MEMBER_SELECT_BATCH_SIZE = 100
    MEMBER_DELETE_BATCH_SIZE = 1_000
    REFERENCE_DELETE_BATCH_SIZE = 1_000
    GROUP_FINDER_MEMBER_RELATIONS = %i[direct inherited shared_from_groups].freeze
    PROJECT_FINDER_MEMBER_RELATIONS = %i[direct inherited invited_groups shared_into_ancestors].freeze
    RELATION_BATCH_SLEEP = 5

    def initialize(import_source_user)
      @import_source_user = import_source_user
      @reassigned_by_user = import_source_user.reassigned_by_user
      @unavailable_tables = []
      @refresh_project_access = false
      @reassignment_throttling = ReassignPlaceholderThrottling.new(import_source_user)
    end

    def execute
      return unless import_source_user.reassignment_in_progress?

      warn_about_any_risky_reassignments

      log_warn('Reassigned by user was not found, this may affect membership checks') unless reassigned_by_user

      begin
        DirectReassignService.new(import_source_user, reassignment_throttling: reassignment_throttling).execute

        reassign_placeholder_references

        delete_remaining_references

        if placeholder_memberships.any?
          create_memberships
          delete_placeholder_memberships
        end

      rescue ReassignPlaceholderThrottling::DatabaseHealthError => error
        return handle_reschedule_error(error, :db_health_check_failed)
      rescue Gitlab::Utils::ExecutionTracker::ExecutionTimeOutError => error
        return handle_reschedule_error(error, :execution_timeout)
      end

      UserProjectAccessChangedService.new(import_source_user.reassign_to_user_id).execute if refresh_project_access?

      import_source_user.complete!

      track_reassignment_complete

      ServiceResponse.success(
        message: s_('Import|Placeholder user record reassignment complete'),
        payload: import_source_user
      )
    end

    private

    attr_accessor :import_source_user, :reassigned_by_user, :reassignment_throttling

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
          next if reassignment_throttling.db_table_unavailable?(model_relation)

          reassignment_throttling.db_health_check!

          reassign_placeholder_records_batch(model_relation, placeholder_references)

          Kernel.sleep RELATION_BATCH_SLEEP
        end

      rescue Import::PlaceholderReferences::AliasResolver::MissingAlias => e
        ::Import::Framework::Logger.error(
          message: "#{reference_group.model} is not a model, " \
            "#{reference_group.user_reference_column} cannot be reassigned.",
          error: e.message,
          source_user_id: import_source_user.id
        )
      end

      return unless reassignment_throttling.unavailable_tables?

      raise ReassignPlaceholderThrottling::DatabaseHealthError, 'Database unhealthy'
    end

    def reassign_placeholder_records_batch(model_relation, placeholder_references)
      aliased_user_reference_column = placeholder_references.first.aliased_user_reference_column
      model_relation.klass.transaction do
        update_count = model_relation.update_all(
          { aliased_user_reference_column => import_source_user.reassign_to_user_id }
        )

        # Temporary log to track for each models/attributes placeholder references are still used
        if log_placeholder_reference_used?(update_count)
          log_info('Placeholder references used', model: model_relation.klass.name,
            user_reference_column: aliased_user_reference_column)
        end
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

    def delete_remaining_references
      source_user_references = ::Import::SourceUserPlaceholderReference.for_source_user(import_source_user)

      source_user_references.each_batch(of: REFERENCE_DELETE_BATCH_SIZE) do |batch|
        batch.delete_all
      end
    end

    def log_placeholder_reference_used?(update_count)
      Feature.enabled?(:user_mapping_direct_reassignment, reassigned_by_user) &&
        update_count > 0 &&
        import_source_user.placeholder_user.placeholder?
    end

    def create_memberships
      # Memberships are not created when the assignee is project bots because
      # membership are already created for them when they are created and they
      # are not allowed to be members of other groups or projects
      return if import_source_user.reassign_to_user.project_bot?

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

      # If user is a member (direct or inherited) with same or higher level, skip creating the membership.
      if existing_membership
        if existing_membership.access_level >= placeholder_membership.access_level
          mark_project_access_changed!(placeholder_membership) if existing_membership.source != memberable
          log_create_membership_skipped('Existing membership of same or higher access level found for user, skipping',
            placeholder_membership, existing_membership)

          return
        end

        # There's an outside chance that the user was already given membership manually
        # to this memberable between the time the import finished and the reassignment process began.
        # In this case, we don't override the existing direct membership, we skip creating it.
        if existing_membership.source == memberable
          log_create_membership_skipped('Existing direct membership of lower access level found for user, skipping',
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

      mark_project_access_changed!(placeholder_membership)
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

    def mark_project_access_changed!(placeholder_membership)
      @refresh_project_access = true if placeholder_membership.project_id
    end

    def refresh_project_access?
      !!@refresh_project_access
    end

    def handle_reschedule_error(error, reason)
      log_warn("#{error.message}. Rescheduling reassignment")
      reschedule_reassignment_response(error.message, reason)
    end

    def reschedule_reassignment_response(message, reason)
      ServiceResponse.error(
        message: message,
        payload: import_source_user,
        reason: reason
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

    def track_reassignment_complete
      track_internal_event(
        'complete_placeholder_user_reassignment',
        namespace: import_source_user.namespace,
        additional_properties: {
          label: Gitlab::GlobalAnonymousId.user_id(import_source_user.placeholder_user),
          property: Gitlab::GlobalAnonymousId.user_id(import_source_user.reassign_to_user),
          import_type: import_source_user.import_type
        }
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
