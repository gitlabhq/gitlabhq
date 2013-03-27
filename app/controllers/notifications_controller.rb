class NotificationsController < ApplicationController
  layout 'profile'

  def show
    @notification = current_user.notification
  end

  def update
    @notification = current_user.notification
  end
end
