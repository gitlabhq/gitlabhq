# frozen_string_literal: true

module Groups
  class DestroyService < Groups::BaseService
    DestroyError = Class.new(StandardError)

    def async_execute
      return UnauthorizedError unless authorize_group_deletion

      mark_deletion_in_progress

      job_id = GroupDestroyWorker.perform_async(group.id, current_user.id)
      Gitlab::AppLogger.info("User #{current_user.id} scheduled a deletion of group ID #{group.id} with job ID #{job_id}")
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def execute
      unless authorize_group_deletion
        group.cancel_deletion!(transition_user: current_user)
        return UnauthorizedError
      end

      ServiceResponse.success(payload: { group: unsafe_execute })
    end

    def unsafe_execute
      mark_deletion_in_progress

      group.projects.includes(:project_feature).find_each do |project|
        # Execute the destruction of the models immediately to ensure atomic cleanup.
        success = ::Projects::DestroyService.new(project, current_user).execute

        raise DestroyError, "Project #{project.id} can't be deleted" unless success
      end

      # reload the relation to prevent triggering destroy hooks on the projects again
      group.projects.reset

      group.children.each do |group|
        # This needs to be synchronous since the namespace gets destroyed below
        DestroyService.new(group, current_user).unsafe_execute
      end

      group.chat_team&.remove_mattermost_team(current_user)

      user_ids_for_project_authorizations_refresh = obtain_user_ids_for_project_authorizations_refresh

      destroy_associated_users
      ::Import::BulkImports::RemoveExportUploadsService.new(group).execute

      group.destroy

      if user_ids_for_project_authorizations_refresh.present?
        UserProjectAccessChangedService
          .new(user_ids_for_project_authorizations_refresh)
          .execute
      end

      publish_event

      group
    rescue Exception => e # rubocop:disable Lint/RescueException -- Namespace.transaction can raise Exception
      log_payload = {
        group_id: group.id,
        current_user: current_user&.id,
        error_class: e.class,
        error_message: e.message,
        error_backtrace: e.backtrace
      }

      reschedule_deletion
      Gitlab::AppLogger.error(log_payload.merge(message: "Rescheduling group deletion"))

      raise e
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def authorize_group_deletion
      raise DestroyError, "You can't delete this group because you're blocked." if current_user.blocked?

      can?(current_user, :remove_group, group)
    end

    def mark_deletion_in_progress
      Group.transaction do
        group.start_deletion!(transition_user: current_user) unless group.deletion_in_progress?
      end
    end

    def reschedule_deletion
      Group.transaction do
        group.reschedule_deletion!(transition_user: current_user)
      end
    end

    def any_groups_shared_with_this_group?
      group.shared_group_links.any?
    end

    def any_projects_shared_with_this_group?
      group.project_group_links.any?
    end

    # Destroying a group automatically destroys all project authorizations directly
    # associated with the group and descendents. However, project authorizations
    # for projects and groups this group is shared with are not. Without a manual
    # refresh, the project authorization records of these users to shared projects
    # and projects within the shared groups will never be removed, causing
    # inconsistencies with access permissions.
    #
    # This method retrieves the user IDs that need to be refreshed. If only
    # groups are shared with this group, only direct members need to be refreshed.
    # If projects are also shared with the group, direct members *and* shared
    # members of other groups need to be refreshed.
    # `Group#user_ids_for_project_authorizations` returns both direct and shared
    # members' user IDs.
    def obtain_user_ids_for_project_authorizations_refresh
      return unless any_projects_shared_with_this_group? || any_groups_shared_with_this_group?
      return group.user_ids_for_project_authorizations if any_projects_shared_with_this_group?

      group.users_ids_of_direct_members
    end

    def destroy_associated_users
      current_user_id = current_user.id
      bot_ids = users_to_destroy

      group.run_after_commit do
        bot_ids.each do |user_id|
          DeleteUserWorker.perform_async(current_user_id, user_id, 'skip_authorization' => true)
        end
      end
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def users_to_destroy
      group.members_and_requesters.joins(:user)
        .merge(User.project_bot)
        .allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/422405')
        .pluck(:user_id)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def publish_event
      event_data = {
        group_id: group.id,
        root_namespace_id: group.root_ancestor&.id.to_i # remove safe navigation and `.to_i` with https://gitlab.com/gitlab-org/gitlab/-/issues/508611
      }
      event_data[:parent_namespace_id] = group.parent_id if group.parent_id.present?

      Gitlab::EventStore.publish(Groups::GroupDeletedEvent.new(data: event_data))
    end
  end
end

Groups::DestroyService.prepend_mod_with('Groups::DestroyService')
