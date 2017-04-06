class Projects::ServiceDeskController < Projects::ApplicationController
  before_action :authorize_admin_project!, only: :update
  before_action :authorize_read_project!, only: :show

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
      attributes =
        { service_desk_address: project.service_desk_address, service_desk_enabled: project.service_desk_enabled }

      format.json { render json: attributes.to_json, status: :ok }
    end
  end
end
