class TestHookContext < BaseContext
  def execute
    hook = project.hooks.find(params[:id])
    commits = project.repository.commits(project.default_branch, nil, 3)
    data = GitPushService.new.execute(project, current_user, commits.last.id, commits.first.id, "refs/heads/#{project.default_branch}")
    hook.execute(data)
  end
end
