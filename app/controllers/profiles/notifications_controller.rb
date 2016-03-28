class Profiles::NotificationsController < Profiles::ApplicationController
  def show
    @user = current_user
    @notification = current_user.notification
    @group_notifications = current_user.notification_settings.for_groups
    @project_notifications = current_user.notification_settings.for_projects
  end

  def update
    type = params[:notification_type]

    @saved = if type == 'global'
               current_user.update_attributes(user_params)
             else
               notification_setting = current_user.notification_settings.find(params[:notification_id])
               notification_setting.level = params[:notification_level]
               notification_setting.save
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
