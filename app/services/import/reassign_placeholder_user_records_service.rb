# frozen_string_literal: true

module Import
  class ReassignPlaceholderUserRecordsService
    MEMBER_SELECT_BATCH_SIZE = 100
    MEMBER_DELETE_BATCH_SIZE = 1_000
    GROUP_FINDER_MEMBER_RELATIONS = %i[direct inherited shared_from_groups].freeze
    PROJECT_FINDER_MEMBER_RELATIONS = %i[direct inherited invited_groups shared_into_ancestors].freeze
    RELATION_BATCH_SLEEP = 5

    def initialize(import_source_user)
      @import_source_user = import_source_user
      @reassigned_by_user = User.find_by_id(import_source_user.reassigned_by_user_id)
    end

    def execute
      return unless import_source_user.reassignment_in_progress?

      warn_about_any_risky_reassignments
      reassign_placeholder_references

      log_warn('Reassigned by user was not found, this may affect membership checks') unless reassigned_by_user

      create_memberships
      delete_placeholder_memberships

      import_source_user.complete!
    end

    private

    attr_accessor :import_source_user, :reassigned_by_user

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
        model = reference_group.model
        user_reference_column = reference_group.user_reference_column

        begin
          Import::SourceUserPlaceholderReference.model_relations_for_source_user_reference(
            model: model,
            source_user: import_source_user,
            user_reference_column: user_reference_column
          ) do |model_relation, placeholder_references|
            reassign_placeholder_records_batch(model_relation, placeholder_references, user_reference_column)

            # TODO: Remove with https://gitlab.com/gitlab-org/gitlab/-/issues/493977
            Kernel.sleep RELATION_BATCH_SLEEP
          end
        rescue NameError => e
          ::Import::Framework::Logger.error(
            message: "#{model} is not a model, #{user_reference_column} cannot be reassigned.",
            error: e.message,
            source_user_id: import_source_user.id
          )

          next
        end
      end
    end

    def reassign_placeholder_records_batch(model_relation, placeholder_references, user_reference_column)
      model_relation.klass.transaction do
        model_relation.update_all({ user_reference_column => import_source_user.reassign_to_user_id })
      end
      placeholder_references.delete_all
    rescue ActiveRecord::RecordNotUnique
      placeholder_references.each do |placeholder_reference|
        reassign_placeholder_record(placeholder_reference, user_reference_column)
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
