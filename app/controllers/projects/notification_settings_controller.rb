class Projects::NotificationSettingsController < Projects::ApplicationController
  before_action :authenticate_user!

  def update
    @notification_setting = current_user.notification_settings_for(project)
    saved = @notification_setting.update_attributes(notification_setting_params)

    render json: {
      html: view_to_html_string("projects/buttons/_notifications", locals: { project: @project, notification_setting: @notification_setting }),
      saved: saved
    }
  end

  private

  def notification_setting_params
    allowed_fields = NotificationSetting::EMAIL_EVENTS.dup
    allowed_fields << :level
    params.require(:notification_setting).permit(allowed_fields)
  end
end
