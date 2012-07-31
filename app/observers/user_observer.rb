class UserObserver < ActiveRecord::Observer
  def after_create(user)
    # We'll not notify using cas for a while

    # Notify.new_user_email(user.id, user.password).deliver
  end
end
