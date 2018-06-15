# frozen_string_literal: true

class ProjectMigrateHashedStorageWorker
  include ApplicationWorker
  include ExclusiveLeaseGuard

  LEASE_TIMEOUT = 30.seconds.to_i

  def perform(project_id)
    project = Project.find_by(id: project_id)
    return if project.nil? || project.pending_delete?

    try_obtain_lease_for(project_id) do
      ::Projects::HashedStorageMigrationService.new(project, logger).execute
    end
  rescue LeaseNotObtained
  end

  private

  def lease_key_for(project_id)
    "project_migrate_hashed_storage_worker:#{project_id}"
  end

  def lease_timeout
    LEASE_TIMEOUT
  end
end
