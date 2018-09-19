class NotificationSettingsController < ApplicationController
  before_action :authenticate_user!

  def create
    return render_404 unless can_read?(resource)

    @notification_setting = current_user.notification_settings_for(resource)
    @saved = @notification_setting.update(notification_setting_params_for(resource))

    render_response
  end

  def update
    @notification_setting = current_user.notification_settings.find(params[:id])
    @saved = @notification_setting.update(notification_setting_params_for(@notification_setting.source))

    render_response
  end

  private

  def resource
    @resource ||=
      if params[:project_id].present?
        Project.find(params[:project_id])
      elsif params[:namespace_id].present?
        Group.find(params[:namespace_id])
      end
  end

  def can_read?(resource)
    ability_name = resource.class.name.downcase
    ability_name = "read_#{ability_name}".to_sym

    can?(current_user, ability_name, resource)
  end

  def render_response
    render json: {
      html: view_to_html_string("shared/notifications/_button", notification_setting: @notification_setting),
      saved: @saved
    }
  end

  def notification_setting_params_for(source)
    allowed_fields = NotificationSetting.email_events(source).dup
    allowed_fields << :level
    params.require(:notification_setting).permit(allowed_fields)
  end
end
