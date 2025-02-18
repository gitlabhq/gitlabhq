# frozen_string_literal: true

class Projects::ServiceDeskController < Projects::ApplicationController
  before_action :authorize_admin_project!

  feature_category :service_desk
  urgency :low

  def show
    json_response
  end

  def update
    Projects::UpdateService.new(project, current_user, { service_desk_enabled: params[:service_desk_enabled] }).execute

    response = ServiceDeskSettings::UpdateService.new(project, current_user, setting_params).execute

    if response.success?
      json_response
    else
      render json: { message: response.message }, status: :unprocessable_entity
    end
  end

  private

  def setting_params
    params.permit(*allowed_update_attributes)
  end

  def allowed_update_attributes
    %i[
      issue_template_key
      outgoing_name
      project_key
      reopen_issue_on_external_participant_note
      add_external_participants_from_cc
      tickets_confidential_by_default
    ]
  end

  def service_desk_attributes
    service_desk_settings = project.service_desk_setting

    {
      service_desk_address: ::ServiceDesk::Emails.new(project).system_address,
      service_desk_enabled: ::ServiceDesk.enabled?(project),
      issue_template_key: service_desk_settings&.issue_template_key,
      template_file_missing: service_desk_settings&.issue_template_missing?,
      outgoing_name: service_desk_settings&.outgoing_name,
      project_key: service_desk_settings&.project_key,
      reopen_issue_on_external_participant_note: service_desk_settings&.reopen_issue_on_external_participant_note,
      add_external_participants_from_cc: service_desk_settings&.add_external_participants_from_cc,
      tickets_confidential_by_default: service_desk_settings&.tickets_confidential_by_default
    }
  end

  def json_response
    respond_to do |format|
      format.json { render json: service_desk_attributes }
    end
  end
end

Projects::ServiceDeskController.prepend_mod
