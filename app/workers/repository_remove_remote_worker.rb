class RepositoryRemoveRemoteWorker
  include ApplicationWorker
  include ExclusiveLeaseGuard

  LEASE_TIMEOUT = 1.hour

  attr_reader :project, :remote_name

  def perform(project_id, remote_name)
    @remote_name = remote_name
    @project = Project.find(project_id)

    try_obtain_lease do
      @project.repository.remove_remote(remote_name)
    end
  end

  def lease_timeout
    LEASE_TIMEOUT
  end

  def lease_key
    "remove_remote_#{project.id}_#{remote_name}"
  end
end
