class CleanupPendingDeleteWorker
  include Sidekiq::Worker
  include CronjobQueue

  MAX_NEW_JOBS = 256

  sidekiq_options retry: false # this job auto-repeats via sidekiq-cron

  def perform
    admin = User.find_by(admin: true)

    Group.with_deleted.where.not(deleted_at: nil).limit(MAX_NEW_JOBS).order(:deleted_at).each do |group|
      GroupDestroyWorker.perform_async(group.id, admin.id)
    end

    Project.unscoped.where(pending_delete: true).limit(MAX_NEW_JOBS).order(:updated_at).each do |project|
      ProjectDestroyWorker.perform_async(project.id, admin.id)
    end
  end
end
