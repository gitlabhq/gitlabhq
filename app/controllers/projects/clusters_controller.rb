class Projects::ClustersController < Projects::ApplicationController
  before_action :cluster, except: [:index, :new]
  before_action :authorize_read_cluster!
  before_action :authorize_create_cluster!, only: [:new]
  before_action :authorize_update_cluster!, only: [:update]
  before_action :authorize_admin_cluster!, only: [:destroy]
  before_action :update_applications_status, only: [:status]

  STATUS_POLLING_INTERVAL = 10_000

  def index
    clusters = ClustersFinder.new(project, current_user, :all).execute
    @clusters = clusters.page(params[:page]).per(20)
  end

  def new
  end

  def status
    respond_to do |format|
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: STATUS_POLLING_INTERVAL)

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
      respond_to do |format|
        format.json do
          head :no_content
        end
        format.html do
          flash[:notice] = _('Kubernetes cluster was successfully updated.')
          redirect_to project_cluster_path(project, cluster)
        end
      end
    else
      respond_to do |format|
        format.json { head :bad_request }
        format.html { render :show }
      end
    end
  end

  def destroy
    if cluster.destroy
      flash[:notice] = _('Kubernetes cluster integration was successfully removed.')
      redirect_to project_clusters_path(project), status: 302
    else
      flash[:notice] = _('Kubernetes cluster integration was not removed.')
      render :show
    end
  end

  private

  def cluster
    @cluster ||= project.clusters.find(params[:id])
                                 .present(current_user: current_user)
  end

  def create_params
    params.require(:cluster).permit(
      :enabled,
      :name,
      :provider_type,
      provider_gcp_attributes: [
        :gcp_project_id,
        :zone,
        :num_nodes,
        :machine_type
      ])
  end

  def update_params
    if cluster.managed?
      params.require(:cluster).permit(
        :enabled,
        :environment_scope,
        platform_kubernetes_attributes: [
          :namespace
        ]
      )
    else
      params.require(:cluster).permit(
        :enabled,
        :name,
        :environment_scope,
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

  def update_applications_status
    @cluster.applications.each(&:schedule_status_update)
  end
end
