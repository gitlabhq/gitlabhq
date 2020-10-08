# frozen_string_literal: true

class Projects::ServiceDeskController < Projects::ApplicationController
  before_action :authorize_admin_project!

  feature_category :service_desk

  def show
    json_response
  end

  def update
    Projects::UpdateService.new(project, current_user, { service_desk_enabled: params[:service_desk_enabled] }).execute

    result = ServiceDeskSettings::UpdateService.new(project, current_user, setting_params).execute

    if result[:status] == :success
      json_response
    else
      render json: { message: result[:message] }, status: :unprocessable_entity
    end
  end

  private

  def setting_params
    params.permit(:issue_template_key, :outgoing_name, :project_key)
  end

  def json_response
    respond_to do |format|
      service_desk_settings = project.service_desk_setting

      service_desk_attributes =
        {
          service_desk_address: project.service_desk_address,
          service_desk_enabled: project.service_desk_enabled,
          issue_template_key: service_desk_settings&.issue_template_key,
          template_file_missing: service_desk_settings&.issue_template_missing?,
          outgoing_name: service_desk_settings&.outgoing_name,
          project_key: service_desk_settings&.project_key
        }

      format.json { render json: service_desk_attributes }
    end
  end
end
