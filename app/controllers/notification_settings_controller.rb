class NotificationSettingsController < ApplicationController
  before_action :authenticate_user!

  def create
    project = current_user.projects.find(params[:project][:id])

    @notification_setting = current_user.notification_settings_for(project)
    @saved = @notification_setting.update_attributes(notification_setting_params)

    render_response
  end

  def update
    @notification_setting = current_user.notification_settings.find(params[:id])
    @saved = @notification_setting.update_attributes(notification_setting_params)

    render_response
  end

  private

  def render_response
    render json: {
      html: view_to_html_string("notifications/buttons/_notifications", notification_setting: @notification_setting),
      saved: @saved
    }
  end

  def notification_setting_params
    allowed_fields = NotificationSetting::EMAIL_EVENTS.dup
    allowed_fields << :level
    params.require(:notification_setting).permit(allowed_fields)
  end
end
