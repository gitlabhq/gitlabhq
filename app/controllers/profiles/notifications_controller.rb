class Profiles::NotificationsController < ApplicationController
  layout 'profile'

  def show
    @notification = current_user.notification
    @users_projects = current_user.project_members
    @users_groups = current_user.group_members
  end

  def update
    type = params[:notification_type]

    @saved = if type == 'global'
               current_user.notification_level = params[:notification_level]
               current_user.save
             elsif type == 'group'
               users_group = current_user.group_members.find(params[:notification_id])
               users_group.notification_level = params[:notification_level]
               users_group.save
             else
               users_project = current_user.project_members.find(params[:notification_id])
               users_project.notification_level = params[:notification_level]
               users_project.save
             end
  end
end
