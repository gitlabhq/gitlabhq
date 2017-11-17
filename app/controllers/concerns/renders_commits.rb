module RendersCommits
  def prepare_commits_for_rendering(commits)
    Banzai::CommitRenderer.render(commits, @project, current_user) # rubocop:disable Cop/ModuleWithInstanceVariables

    commits
  end
end
