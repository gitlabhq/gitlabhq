# frozen_string_literal: true

module ProjectCommitCount
  include Gitlab::Git::WrapsGitalyErrors

  def commit_count_for(project, default_count: 0, max_count: nil, **exception_details)
    raw_repo = project.repository&.raw_repository
    root_ref = raw_repo&.root_ref

    return default_count unless root_ref

    Gitlab::GitalyClient::CommitService.new(raw_repo).commit_count(root_ref, {
      all: true, # include all branches
      max_count: max_count # limit as an optimization
    })
  rescue StandardError => e
    Gitlab::ErrorTracking.track_exception(e, exception_details)

    default_count
  end
end
