class RepositoryUpdateMirrorDispatchWorker
  include Sidekiq::Worker

  LEASE_TIMEOUT = 5.minutes

  sidekiq_options queue: :gitlab_shell

  attr_accessor :project, :repository, :current_user

  def perform(project_id)
    return unless try_obtain_lease(project_id)

    @project = Project.find_by_id(project_id)
    return unless project

    project.update_mirror
  end

  private

  def try_obtain_lease(project_id)
    # Using 5 minutes timeout based on the 95th percent of timings (currently max of 25 minutes)
    lease = ::Gitlab::ExclusiveLease.new("repository_update_mirror_dispatcher:#{project_id}", timeout: LEASE_TIMEOUT)
    lease.try_obtain
  end
end
