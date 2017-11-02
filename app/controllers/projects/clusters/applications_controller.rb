class Projects::Clusters::ApplicationsController < Projects::ApplicationController
  before_action :cluster
  before_action :application_class, only: [:create]
  before_action :authorize_read_cluster!
  before_action :authorize_create_cluster!, only: [:create]

  def new
  end

  def create
    return render_404 if application

    new_application = application_class.create(cluster: cluster)

    respond_to do |format|
      format.json do
        if new_application.persisted?
          head :ok
        else
          head :bad_request
        end
      end
    end
  end

  private

  def cluster
    @cluster ||= project.clusters.find_by(cluster_id: params[:cluster_id]).present(current_user: current_user)
  end

  def application_class
    Clusters::Cluster::Applications.find(params[:application])
  end

  def application
    application_class.find_by(cluster: cluster)
  end
end
