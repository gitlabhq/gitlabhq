class UsersProjectObserver < ActiveRecord::Observer
  #def after_create(users_project)
    #Notify.project_access_granted_email(users_project.id).deliver
  #end

  #def after_update(users_project)
    #Notify.project_access_granted_email(users_project.id).deliver
  #end

  def after_commit(users_project)
    Notify.project_access_granted_email(users_project.id).deliver
  end
end
