class SystemHookObserver < BaseObserver
  observe :user, :project, :users_project

  def after_create(model)
    system_hook_service.execute_hooks_for(model, :create)
  end

  def after_destroy(model)
    system_hook_service.execute_hooks_for(model, :destroy)
  end

  private

  def system_hook_service
    SystemHooksService.new
  end
end
