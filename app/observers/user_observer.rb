class UserObserver < ActiveRecord::Observer
  def after_create(user)
    #TODO fix to remove password from Notify.new_user_email
    #Notify.new_user_email(user.id, user.password).deliver
  end
end
