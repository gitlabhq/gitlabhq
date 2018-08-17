# frozen_string_literal: true

module Groups
  class DestroyService < Groups::BaseService
    prepend ::EE::Groups::DestroyService

    DestroyError = Class.new(StandardError)

    def async_execute
      job_id = GroupDestroyWorker.perform_async(group.id, current_user.id)
      Rails.logger.info("User #{current_user.id} scheduled a deletion of group ID #{group.id} with job ID #{job_id}")
    end

    def execute
      group.prepare_for_destroy

      group.projects.each do |project|
        # Execute the destruction of the models immediately to ensure atomic cleanup.
        success = ::Projects::DestroyService.new(project, current_user).execute
        raise DestroyError, "Project #{project.id} can't be deleted" unless success
      end

      group.children.each do |group|
        # This needs to be synchronous since the namespace gets destroyed below
        DestroyService.new(group, current_user).execute
      end

      group.chat_team&.remove_mattermost_team(current_user)

      group.destroy
    end
  end
end
