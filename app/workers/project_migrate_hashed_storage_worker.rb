class ProjectMigrateHashedStorageWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  LEASE_TIMEOUT = 30.seconds.to_i

  def perform(project_id)
    project = Project.find_by(id: project_id)
    return if project.nil? || project.pending_delete?

    uuid = try_obtain_lease_for(project_id)
    if uuid
      ::Projects::HashedStorageMigrationService.new(project, logger).execute
    else
      false
    end
  rescue => ex
    cancel_lease_for(project_id, uuid)
    raise ex
  end

  private

  def try_obtain_lease_for(project_id)
    Gitlab::ExclusiveLease.new(lease_key(project_id), timeout: LEASE_TIMEOUT).try_obtain
  end

  def lease_key(project_id)
    "project_migrate_hashed_storage_worker:#{project_id}"
  end

  def cancel_lease_for(project_id, uuid)
    Gitlab::ExclusiveLease.cancel(lease_key(project_id), uuid)
  end
end
