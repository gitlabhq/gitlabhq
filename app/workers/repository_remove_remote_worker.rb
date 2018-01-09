class RepositoryRemoveRemoteWorker
  include ApplicationWorker

  LEASE_TIMEOUT = 1.hour

  def perform(project_id, remote_name)
    lease_uuid = try_obtain_lease(project_id)
    return unless lease_uuid

    project = Project.find(project_id)
    project.repository.remove_remote(remote_name)

    cancel_lease(project_id, lease_uuid)
  end

  private

  def lease_key(project_id)
    "remove_remote_#{project_id}"
  end

  def try_obtain_lease(id)
    key = lease_key(id)

    Gitlab::ExclusiveLease.new(key, timeout: LEASE_TIMEOUT).try_obtain
  end

  def cancel_lease(id, uuid)
    key = lease_key(id)

    Gitlab::ExclusiveLease.cancel(key, uuid)
  end
end
