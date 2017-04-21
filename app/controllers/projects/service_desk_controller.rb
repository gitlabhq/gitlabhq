class Projects::ServiceDeskController < Projects::ApplicationController
  before_action :authorize_admin_project!

  def show
    json_response
  end

  def update
    Projects::UpdateService.new(project, current_user, { service_desk_enabled: params[:service_desk_enabled] }).execute

    json_response
  end

  private

  def json_response
    respond_to do |format|
      service_desk_attributes =
        { service_desk_address: project.service_desk_address, service_desk_enabled: project.service_desk_enabled }

      format.json { render json: service_desk_attributes }
    end
  end
end
