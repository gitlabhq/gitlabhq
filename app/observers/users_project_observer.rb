class UsersProjectObserver < ActiveRecord::Observer
  def after_create(users_project)
    Notify.project_access_granted_email(users_project.id).deliver

    Event.create(
      project_id: users_project.project.id,
      action: Event::Joined,
      author_id: users_project.user.id
    )
  end

  def after_update(users_project)
    Notify.project_access_granted_email(users_project.id).deliver
  end

  def after_destroy(users_project)
    Event.create(
      project_id: users_project.project.id, 
      action: Event::Left, 
      author_id: users_project.user.id
    )
  end

end
