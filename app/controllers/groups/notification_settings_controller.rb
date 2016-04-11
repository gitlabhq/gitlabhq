class Groups::NotificationSettingsController < Groups::ApplicationController
  before_action :authenticate_user!

  def update
    notification_setting = current_user.notification_settings_for(group)
    saved = notification_setting.update_attributes(notification_setting_params)

    render json: { saved: saved }
  end

  private

  def notification_setting_params
    params.require(:notification_setting).permit(:level)
  end
end
