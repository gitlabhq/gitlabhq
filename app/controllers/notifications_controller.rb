class NotificationsController < ApplicationController
  layout 'profile'

  def show
    @notification = current_user.notification
    @projects = current_user.authorized_projects
  end

  def update
    current_user.notification_level = params[:notification_level]
    @saved = current_user.save
  end
end
