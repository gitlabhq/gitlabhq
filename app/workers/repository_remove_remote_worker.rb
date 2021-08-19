# frozen_string_literal: true

class RepositoryRemoveRemoteWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include ExclusiveLeaseGuard

  feature_category :source_code_management
  loggable_arguments 1

  LEASE_TIMEOUT = 1.hour

  attr_reader :project, :remote_name

  def perform(project_id, remote_name)
    # On-disk remotes are slated for removal, and GitLab doesn't create any of
    # them anymore. For backwards compatibility, we need to keep the worker
    # though such that we can be sure to drain all jobs on an update. Making
    # this a no-op is fine though: the worst that can happen is that we still
    # have old remotes lingering in the repository's config, but Gitaly will
    # start to clean these up in repository maintenance.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/336745
  end

  def lease_timeout
    LEASE_TIMEOUT
  end

  def lease_key
    "remove_remote_#{project.id}_#{remote_name}"
  end
end
