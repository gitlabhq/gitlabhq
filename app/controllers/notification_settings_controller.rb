class NotificationSettingsController < ApplicationController
  before_action :authenticate_user!

  def create
    project = Project.find(params[:project][:id])

    if can?(current_user, :read_project, project)
      @notification_setting = current_user.notification_settings_for(project)
      @saved = @notification_setting.update_attributes(notification_setting_params)

      render_response
    else
      render_404
    end
  end

  def update
    @notification_setting = current_user.notification_settings.find(params[:id])
    @saved = @notification_setting.update_attributes(notification_setting_params)

    render_response
  end

  private

  def render_response
    render json: {
      html: view_to_html_string("shared/notifications/buttons/_button", notification_setting: @notification_setting),
      saved: @saved
    }
  end

  def notification_setting_params
    allowed_fields = NotificationSetting::EMAIL_EVENTS.dup
    allowed_fields << :level
    params.require(:notification_setting).permit(allowed_fields)
  end
end
