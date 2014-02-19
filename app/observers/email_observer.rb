class EmailObserver < BaseObserver
  def after_create(email)
    notification.new_email(email)
  end
end
