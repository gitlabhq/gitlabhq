class Profiles::NotificationsController < Profiles::ApplicationController
  def show
    @user = current_user
    @group_notifications = current_user.notification_settings.for_groups
    @project_notifications = current_user.notification_settings.for_projects
  end

  def update
    if current_user.update_attributes(user_params)
      flash[:notice] = "Notification settings saved"
    else
      flash[:alert] = "Failed to save new settings"
    end

    redirect_back_or_default(default: profile_notifications_path)
  end

  def user_params
    params.require(:user).permit(:notification_email, :notification_level)
  end
end
