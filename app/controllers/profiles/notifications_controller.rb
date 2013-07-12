class Profiles::NotificationsController < ApplicationController
  layout 'profile'

  def show
    @notification = current_user.notification
    @users_projects = current_user.users_projects
    @users_groups = current_user.users_groups
  end

  def update
    type = params[:notification_type]

    @saved = if type == 'global'
               current_user.notification_level = params[:notification_level]
               current_user.save
             elsif type == 'group'
               users_group = current_user.users_groups.find(params[:notification_id])
               users_group.notification_level = params[:notification_level]
               users_group.save
             else
               users_project = current_user.users_projects.find(params[:notification_id])
               users_project.notification_level = params[:notification_level]
               users_project.save
             end
  end
end
