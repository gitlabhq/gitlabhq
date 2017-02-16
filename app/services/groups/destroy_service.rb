module Groups
  class DestroyService < Groups::BaseService
    def async_execute
      # Soft delete via paranoia gem
      group.destroy
      job_id = GroupDestroyWorker.perform_async(group.id, current_user.id)
      Rails.logger.info("User #{current_user.id} scheduled a deletion of group ID #{group.id} with job ID #{job_id}")
    end

    def execute
      group.prepare_for_destroy

      group.projects.with_deleted.each do |project|
        # Execute the destruction of the models immediately to ensure atomic cleanup.
        # Skip repository removal because we remove directory with namespace
        # that contain all these repositories
        ::Projects::DestroyService.new(project, current_user, skip_repo: true).execute
      end

      group.children.each do |group|
        DestroyService.new(group, current_user).async_execute
      end

      group.really_destroy!
    end
  end
end
