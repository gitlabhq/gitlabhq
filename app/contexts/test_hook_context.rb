class TestHookContext < BaseContext
  def execute
    hook = project.hooks.find(params[:id])
    commits = project.repository.commits(project.default_branch, nil, 3)
    data = project.post_receive_data(commits.last.id, commits.first.id, "refs/heads/#{project.default_branch}", current_user)
    hook.execute(data)
  end
end
