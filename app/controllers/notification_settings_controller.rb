# frozen_string_literal: true

class NotificationSettingsController < ApplicationController
  before_action :authenticate_user!

  feature_category :users

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
    btn_class = nil

    if params[:hide_label].present?
      btn_class = 'btn-xs' if params[:project_id].present?
      response_template = 'shared/notifications/_new_button'
    else
      response_template = 'shared/notifications/_button'
    end

    render json: {
      html: view_to_html_string(response_template, notification_setting: @notification_setting, btn_class: btn_class),
      saved: @saved
    }
  end

  def notification_setting_params_for(source)
    params.require(:notification_setting).permit(NotificationSetting.allowed_fields(source))
  end
end
