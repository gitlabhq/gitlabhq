# frozen_string_literal: true

class ProjectMigrateHashedStorageWorker
  include ApplicationWorker

  LEASE_TIMEOUT = 30.seconds.to_i
  LEASE_KEY_SEGMENT = 'project_migrate_hashed_storage_worker'.freeze

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(project_id, old_disk_path = nil)
    uuid = lease_for(project_id).try_obtain

    if uuid
      project = Project.find_by(id: project_id)
      return if project.nil? || project.pending_delete?

      old_disk_path ||= project.disk_path

      ::Projects::HashedStorage::MigrationService.new(project, old_disk_path, logger: logger).execute
    else
      return false
    end

  ensure
    cancel_lease_for(project_id, uuid) if uuid
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def lease_for(project_id)
    Gitlab::ExclusiveLease.new(lease_key(project_id), timeout: LEASE_TIMEOUT)
  end

  private

  def lease_key(project_id)
    # we share the same lease key for both migration and rollback so they don't run simultaneously
    "#{LEASE_KEY_SEGMENT}:#{project_id}"
  end

  def cancel_lease_for(project_id, uuid)
    Gitlab::ExclusiveLease.cancel(lease_key(project_id), uuid)
  end
end
