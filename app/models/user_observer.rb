class UserObserver < ActiveRecord::Observer
  def after_create(user)
    Notify.new_user_email(user.id, user.password).deliver
  end
end
