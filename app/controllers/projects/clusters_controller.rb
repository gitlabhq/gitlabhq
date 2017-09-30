class Projects::ClustersController < Projects::ApplicationController
  before_action :cluster, except: [:login, :index, :new, :create]
  before_action :authorize_google_api, except: [:login]
  # before_action :cluster_creation_lock, only: [:update, :destroy]
  # before_action :authorize_admin_clusters! # TODO: Authentication

  def login
    begin
      @authorize_url = GoogleApi::CloudPlatform::Client.new(
          nil,
          callback_google_api_authorizations_url,
          state: namespace_project_clusters_url.to_s
        ).authorize_url
    rescue GoogleApi::Auth::ConfigMissingError
      # Show an alert message that gitlab.yml is not configured properly
    end
  end

  def index
    if project.clusters.any?
      redirect_to edit_project_cluster_path(project, project.clusters.last.id)
    else
      redirect_to new_project_cluster_path(project)
    end
  end

  def new
    @cluster = project.clusters.new
  end

  def create
    @cluster = Ci::CreateClusterService
      .new(project, current_user, cluster_params)
      .execute(token_in_session)

    if @cluster.persisted?
      ClusterCreationWorker.perform_async(@cluster.id)
      redirect_to project_clusters_path(project)
    else
      render :new
    end
  end

  def status
    respond_to do |format|
      format.json do
        render json: {
          status: cluster.status, # The current status of the operation.
          status_reason: cluster.status_reason # If an error has occurred, a textual description of the error.
        }
      end
    end
  end

  def edit
  end

  def update
    Ci::UpdateClusterService
      .new(project, current_user, cluster_params)
      .execute(cluster)

    render :edit
  end

  def destroy
    if cluster.destroy
      redirect_to project_clusters_path(project), status: 302
    else
      redirect_to project_clusters_path(project),
                  status: :forbidden,
                  alert: _("Failed to remove the cluster")
    end
  end

  private

  def cluster
    @cluster ||= project.clusters.find(params[:id])
  end

  def cluster_params
    params.require(:cluster)
      .permit(:gcp_project_id, :cluster_zone, :cluster_name, :cluster_size,
              :machine_type, :project_namespace, :enabled)
  end

  def authorize_google_api
    unless token_in_session
      redirect_to action: 'login'
    end
  end

  def token_in_session
    @token_in_session ||= session[GoogleApi::CloudPlatform::Client.session_key_for_token]
  end

  def cluster_creation_lock
    if cluster.on_creation?
      redirect_to edit_project_cluster_path(project, cluster),
                  status: :forbidden,
                  alert: _("You can not modify cluster during creation")
    end
  end
end
