class Projects::NotificationSettingsController < Projects::ApplicationController
  def create
    notification_setting = project.notification_settings.new(notification_setting_params)
    notification_setting.user = current_user
    saved = notification_setting.save

    render json: { saved: saved }
  end

  def update
    notification_setting = project.notification_settings.find_by(user_id: current_user)
    saved = notification_setting.update_attributes(notification_setting_params)

    render json: { saved: saved }
  end

  private

  def notification_setting_params
    params.require(:notification_setting).permit(:level)
  end
end
