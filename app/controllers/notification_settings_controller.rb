class NotificationSettingsController < ApplicationController
  before_action :authenticate_user!

  def create
    resource = find_resource

    return render_404 unless can_read?(resource)

    @notification_setting = current_user.notification_settings_for(resource)
    @saved = @notification_setting.update_attributes(notification_setting_params)

    render_response
  end

  def update
    @notification_setting = current_user.notification_settings.find(params[:id])
    @saved = @notification_setting.update_attributes(notification_setting_params)

    render_response
  end

  private

  def find_resource
    resource =
      if params[:project].present?
        Project.find(params[:project][:id])
      elsif params[:namespace].present?
        Group.find(params[:namespace][:id])
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

  def notification_setting_params
    allowed_fields = NotificationSetting::EMAIL_EVENTS.dup
    allowed_fields << :level
    params.require(:notification_setting).permit(allowed_fields)
  end
end
