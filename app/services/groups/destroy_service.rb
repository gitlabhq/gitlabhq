# frozen_string_literal: true

module Groups
  class DestroyService < Groups::BaseService
    DestroyError = Class.new(StandardError)

    def async_execute
      job_id = GroupDestroyWorker.perform_async(group.id, current_user.id)
      Gitlab::AppLogger.info("User #{current_user.id} scheduled a deletion of group ID #{group.id} with job ID #{job_id}")
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def execute
      group.prepare_for_destroy

      group.projects.includes(:project_feature).each do |project|
        # Execute the destruction of the models immediately to ensure atomic cleanup.
        success = ::Projects::DestroyService.new(project, current_user).execute
        raise DestroyError, "Project #{project.id} can't be deleted" unless success
      end

      # reload the relation to prevent triggering destroy hooks on the projects again
      group.projects.reset

      group.children.each do |group|
        # This needs to be synchronous since the namespace gets destroyed below
        DestroyService.new(group, current_user).execute
      end

      group.chat_team&.remove_mattermost_team(current_user)

      user_ids_for_project_authorizations_refresh = obtain_user_ids_for_project_authorizations_refresh

      group.destroy

      if user_ids_for_project_authorizations_refresh.present?
        UserProjectAccessChangedService
          .new(user_ids_for_project_authorizations_refresh)
          .execute(blocking: true)
      end

      group
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

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
  end
end

Groups::DestroyService.prepend_mod_with('Groups::DestroyService')
