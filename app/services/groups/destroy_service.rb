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

      # If any other groups are shared with the group that is being destroyed,
      # we should specifically trigger update of all project authorizations
      # for users that are the direct members of this group.
      # If not, the project authorization records of these users to projects within the shared groups
      # will never be removed, causing inconsistencies with access permissions.
      if any_other_groups_are_shared_with_this_group?
        user_ids_for_project_authorizations_refresh = group.users_ids_of_direct_members
      end

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

    def any_other_groups_are_shared_with_this_group?
      group.shared_group_links.any?
    end
  end
end

Groups::DestroyService.prepend_mod_with('Groups::DestroyService')
