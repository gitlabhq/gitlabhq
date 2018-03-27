module Groups
  class DestroyService < Groups::BaseService
    def async_execute
      job_id = GroupDestroyWorker.perform_async(group.id, current_user.id)
      Rails.logger.info("User #{current_user.id} scheduled a deletion of group ID #{group.id} with job ID #{job_id}")
    end

    def execute
      group.prepare_for_destroy

      group.projects.each do |project|
        # Execute the destruction of the models immediately to ensure atomic cleanup.
        # Skip repository removal because we remove directory with namespace
        # that contain all these repositories
        ::Projects::DestroyService.new(project, current_user, skip_repo: project.legacy_storage?).execute
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
