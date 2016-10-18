class CleanupPendingDeleteWorker
  include Sidekiq::Worker

  sidekiq_options retry: false # this job auto-repeats via sidekiq-cron

  def perform
    admin = User.find_by(admin: true)

    Project.unscoped.where(pending_delete: true).find_each do |project|
      ProjectDestroyWorker.perform_async(project.id, admin.id)
    end
  end
end
