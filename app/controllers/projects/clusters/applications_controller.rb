# frozen_string_literal: true

class Projects::Clusters::ApplicationsController < Projects::ApplicationController
  before_action :cluster
  before_action :authorize_read_cluster!
  before_action :authorize_create_cluster!, only: [:create]

  def create
    application = Clusters::Applications::CreateService
      .new(@cluster, current_user, create_cluster_application_params)
      .execute(request)

    Clusters::Applications::ScheduleInstallationService.new(project, current_user).execute(application)

    head :no_content
  rescue Clusters::Applications::CreateService::InvalidApplicationError
    render_404
  rescue StandardError
    head :bad_request
  end

  private

  def cluster
    @cluster ||= project.clusters.find(params[:id]) || render_404
  end

  def create_cluster_application_params
    params.permit(:application, :hostname)
  end
end
