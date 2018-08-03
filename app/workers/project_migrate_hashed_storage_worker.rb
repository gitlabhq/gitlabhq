# frozen_string_literal: true

class ProjectMigrateHashedStorageWorker
  include ApplicationWorker

  LEASE_TIMEOUT = 30.seconds.to_i

  def perform(project_id, old_disk_path = nil)
    project = Project.find_by(id: project_id)
    return if project.nil? || project.pending_delete?

    uuid = lease_for(project_id).try_obtain
    if uuid
      ::Projects::HashedStorageMigrationService.new(project, old_disk_path || project.full_path, logger: logger).execute
    else
      false
    end
  rescue => ex
    cancel_lease_for(project_id, uuid) if uuid
    raise ex
  end

  def lease_for(project_id)
    Gitlab::ExclusiveLease.new(lease_key(project_id), timeout: LEASE_TIMEOUT)
  end

  private

  def lease_key(project_id)
    "project_migrate_hashed_storage_worker:#{project_id}"
  end

  def cancel_lease_for(project_id, uuid)
    Gitlab::ExclusiveLease.cancel(lease_key(project_id), uuid)
  end
end
