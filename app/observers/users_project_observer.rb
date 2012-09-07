class UsersProjectObserver < ActiveRecord::Observer
  def after_commit(users_project)
    return if users_project.destroyed?
    Notify.project_access_granted_email(users_project.id).deliver
  end
end
