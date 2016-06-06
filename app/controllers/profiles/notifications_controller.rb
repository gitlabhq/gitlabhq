class Profiles::NotificationsController < Profiles::ApplicationController
  def show
    @user                        = current_user
    @group_notifications         = current_user.notification_settings.for_groups
    @project_notifications       = current_user.notification_settings.for_projects
    @global_notification_setting = current_user.global_notification_setting
  end

  def update
    if current_user.update_attributes(user_params) && update_notification_settings
      flash[:notice] = "Notification settings saved"
    else
      flash[:alert] = "Failed to save new settings"
    end

    redirect_back_or_default(default: profile_notifications_path)
  end

  def user_params
    params.require(:user).permit(:notification_email, :notification_level)
  end

  def notification_params
    params.require(:notification_level)
  end

  private

  def update_notification_settings
    return true unless notification_params

    notification_setting = current_user.global_notification_setting
    notification_setting.level = notification_params

    notification_setting.save
  end
end
