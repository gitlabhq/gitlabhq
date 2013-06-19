module Projects
  class TestHookContext < Projects::BaseContext
    def execute
      hook = project.hooks.find(params[:id])
      data = GitPushService.new.sample_data(project, current_user)
      hook.execute(data)
    end
  end
end
