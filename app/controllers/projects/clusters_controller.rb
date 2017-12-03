class Projects::ClustersController < Projects::ApplicationController
  before_action :cluster, except: [:index, :new]
  before_action :authorize_read_cluster!
  before_action :authorize_create_cluster!, only: [:new]
  before_action :authorize_update_cluster!, only: [:update]
  before_action :authorize_admin_cluster!, only: [:destroy]

  def index
    if project.cluster
      redirect_to project_cluster_path(project, project.cluster)
    else
      redirect_to new_project_cluster_path(project)
    end
  end

  def new
  end

  def status
    respond_to do |format|
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: 10_000)

        render json: ClusterSerializer
          .new(project: @project, current_user: @current_user)
          .represent_status(@cluster)
      end
    end
  end

  def show
  end

  def update
    Clusters::UpdateService
      .new(project, current_user, update_params)
      .execute(cluster)

    if cluster.valid?
      flash[:notice] = "Cluster was successfully updated."
      redirect_to project_cluster_path(project, project.cluster)
    else
      render :show
    end
  end

  def destroy
    if cluster.destroy
      flash[:notice] = "Cluster integration was successfully removed."
      redirect_to project_clusters_path(project), status: 302
    else
      flash[:notice] = "Cluster integration was not removed."
      render :show
    end
  end

  private

  def cluster
    @cluster ||= project.clusters.find(params[:id]).present(current_user: current_user) || render_404
  end

  def update_params
    if cluster.managed?
      params.require(:cluster).permit(
        :enabled,
        platform_kubernetes_attributes: [
          :namespace
        ]
      )
    else
      params.require(:cluster).permit(
        :enabled,
        :name,
        platform_kubernetes_attributes: [
          :api_url,
          :token,
          :ca_cert,
          :namespace
        ] 
      )
    end
  end

  def authorize_update_cluster!
    access_denied! unless can?(current_user, :update_cluster, cluster)
  end

  def authorize_admin_cluster!
    access_denied! unless can?(current_user, :admin_cluster, cluster)
  end
end
