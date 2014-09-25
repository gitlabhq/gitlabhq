class Profiles::NotificationsController < ApplicationController
  layout 'profile'

  def show
    @notification = current_user.notification
    @project_members = current_user.project_members
    @group_members = current_user.group_members
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
               project_member = current_user.project_members.find(params[:notification_id])
               project_member.notification_level = params[:notification_level]
               project_member.save
             end
  end
end
