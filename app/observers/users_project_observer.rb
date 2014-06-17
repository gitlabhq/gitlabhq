class UsersProjectObserver < BaseObserver
  def after_create(users_project)
    Event.create(
      project_id: users_project.project.id,
      action: Event::JOINED,
      author_id: users_project.user.id
    )

    notification.new_team_member(users_project)
    system_hook_service.execute_hooks_for(users_project, :create)
  end

  def after_update(users_project)
    notification.update_team_member(users_project) if users_project.project_access_changed?
  end

  def after_destroy(users_project)
    Event.create(
      project_id: users_project.project.id,
      action: Event::LEFT,
      author_id: users_project.user.id
    )
    system_hook_service.execute_hooks_for(users_project, :destroy)
  end
end
