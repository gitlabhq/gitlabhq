class Profiles::NotificationsController < Profiles::ApplicationController
  def show
    @user = current_user
    @notification = current_user.notification
    @project_members = current_user.project_members
    @group_members = current_user.group_members
  end

  def update
    type = params[:notification_type]

    @saved = if type == 'global'
               current_user.update_attributes(user_params)
             elsif type == 'group'
               group_member = current_user.group_members.find(params[:notification_id])
               group_member.notification_level = params[:notification_level]
               group_member.save
             else
               project_member = current_user.project_members.find(params[:notification_id])
               project_member.notification_level = params[:notification_level]
               project_member.save
             end

    respond_to do |format|
      format.html do
        if @saved
          flash[:notice] = "Notification settings saved"
        else
          flash[:alert] = "Failed to save new settings"
        end

        redirect_back_or_default(default: profile_notifications_path)
      end

      format.js
    end
  end

  def user_params
    params.require(:user).permit(:notification_email, :notification_level)
  end
end
