module RendersCommits
  def limited_commits(commits)
    if commits.size > MergeRequestDiff::COMMITS_SAFE_SIZE
      [
        commits.first(MergeRequestDiff::COMMITS_SAFE_SIZE),
        commits.size - MergeRequestDiff::COMMITS_SAFE_SIZE
      ]
    else
      [commits, 0]
    end
  end

  # This is used as a helper method in a controller.
  # rubocop: disable Gitlab/ModuleWithInstanceVariables
  def set_commits_for_rendering(commits)
    @total_commit_count = commits.size
    limited, @hidden_commit_count = limited_commits(commits)
    prepare_commits_for_rendering(limited)
  end
  # rubocop: enable Gitlab/ModuleWithInstanceVariables

  def prepare_commits_for_rendering(commits)
    Banzai::CommitRenderer.render(commits, @project, current_user) # rubocop:disable Gitlab/ModuleWithInstanceVariables

    commits
  end
end
