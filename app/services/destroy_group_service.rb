class DestroyGroupService
  attr_accessor :group, :current_user

  def initialize(group, user)
    @group, @current_user = group, user
  end

  def async_execute
    group.transaction do
      # Soft delete via paranoia gem
      group.destroy
      job_id = GroupDestroyWorker.perform_async(group.id, current_user.id)
      Rails.logger.info("User #{current_user.id} scheduled a deletion of group ID #{group.id} with job ID #{job_id}")
    end
  end

  def execute
    group.projects.each do |project|
      # Execute the destruction of the models immediately to ensure atomic cleanup.
      # Skip repository removal because we remove directory with namespace
      # that contain all these repositories
      ::Projects::DestroyService.new(project, current_user, skip_repo: true).execute
    end

    group.really_destroy!
  end
end
