# frozen_string_literal: true

module RendersCommits
  def limited_commits(commits, commits_count)
    if commits_count > MergeRequestDiff::COMMITS_SAFE_SIZE
      [
        commits.first(MergeRequestDiff::COMMITS_SAFE_SIZE),
        commits_count - MergeRequestDiff::COMMITS_SAFE_SIZE
      ]
    else
      [commits, 0]
    end
  end

  # This is used as a helper method in a controller.
  # rubocop: disable Gitlab/ModuleWithInstanceVariables
  def set_commits_for_rendering(commits, commits_count: nil)
    @total_commit_count = commits_count || commits.size
    limited, @hidden_commit_count = limited_commits(commits, @total_commit_count)
    commits.each(&:lazy_author) # preload authors
    prepare_commits_for_rendering(limited)
  end
  # rubocop: enable Gitlab/ModuleWithInstanceVariables

  def prepare_commits_for_rendering(commits)
    Banzai::CommitRenderer.render(commits, @project, current_user) # rubocop:disable Gitlab/ModuleWithInstanceVariables

    commits
  end

  def valid_ref?(ref_name)
    return true unless ref_name.present?

    Gitlab::GitRefValidator.validate(ref_name)
  end
end
