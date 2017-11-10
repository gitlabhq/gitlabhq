class Projects::Clusters::ApplicationsController < Projects::ApplicationController
  before_action :cluster
  before_action :application_class, only: [:create]
  before_action :authorize_read_cluster!
  before_action :authorize_create_cluster!, only: [:create]

  def create
    Clusters::Applications::ScheduleInstallationService.new(project, current_user,
                                                            application_class: @application_class,
                                                            cluster: @cluster).execute
    head :no_content
  rescue StandardError
    head :bad_request
  end

  private

  def cluster
    @cluster ||= project.clusters.find(params[:id]) || render_404
  end

  def application_class
    @application_class ||= Clusters::Cluster::APPLICATIONS[params[:application]] || render_404
  end
end
