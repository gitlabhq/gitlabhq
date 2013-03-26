class SystemHookObserver < BaseObserver
  observe :user, :project, :users_project

  def after_create(model)
    SystemHooksService.execute_hooks_for(model, :create)
  end

  def after_destroy(model)
    SystemHooksService.execute_hooks_for(model, :destroy)
  end
end
