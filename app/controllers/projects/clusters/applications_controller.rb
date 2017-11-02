class Projects::Clusters::ApplicationsController < Projects::ApplicationController
  before_action :cluster
  before_action :application_class, only: [:create]
  before_action :authorize_read_cluster!
  before_action :authorize_create_cluster!, only: [:create]

  def create
    return render_404 if application

    respond_to do |format|
      format.json do
        # TODO: Do that via Service
        if application_class.create(cluster: cluster).persisted?
          head :no_data
        else
          head :bad_request
        end
      end
    end
  end

  private

  def cluster
    @cluster ||= project.clusters.find(params[:id]) || render_404
  end

  def application_class
    Clusters::Cluster::APPLICATIONS[params[:application]] || render_404
  end

  def application
    application_class.find_by(cluster: cluster)
  end
end
