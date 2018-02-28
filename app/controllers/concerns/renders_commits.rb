module RendersCommits
  def prepare_commits_for_rendering(commits)
    Banzai::CommitRenderer.render(commits, @project, current_user)

    commits
  end
end
