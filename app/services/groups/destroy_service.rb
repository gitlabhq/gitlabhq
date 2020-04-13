# frozen_string_literal: true

module Groups
  class DestroyService < Groups::BaseService
    DestroyError = Class.new(StandardError)

    def async_execute
      job_id = GroupDestroyWorker.perform_async(group.id, current_user.id)
      Rails.logger.info("User #{current_user.id} scheduled a deletion of group ID #{group.id} with job ID #{job_id}") # rubocop:disable Gitlab/RailsLogger
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

      user_ids_for_project_authorizations_refresh = group.user_ids_for_project_authorizations

      group.destroy

      UserProjectAccessChangedService
        .new(user_ids_for_project_authorizations_refresh)
        .execute(blocking: true)

      group
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end

Groups::DestroyService.prepend_if_ee('EE::Groups::DestroyService')
