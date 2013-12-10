class UsersProjectObserver < BaseObserver
  def after_create(users_project)
    Event.create(
      project_id: users_project.project.id,
      action: Event::JOINED,
      author_id: users_project.user.id
    )

    notification.new_team_member(users_project)
  end

  def after_update(users_project)
    notification.update_team_member(users_project)
  end

  def after_destroy(users_project)
    Event.create(
      project_id: users_project.project.id,
      action: Event::LEFT,
      author_id: users_project.user.id
    )
  end
end
