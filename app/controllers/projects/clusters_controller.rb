class Projects::ClustersController < Projects::ApplicationController
  before_action :cluster, except: [:login, :index, :new, :create]
  before_action :authorize_admin_cluster!
  before_action :authorize_google_api, except: [:login]

  def login
    begin
      @authorize_url = GoogleApi::CloudPlatform::Client.new(
          nil, callback_google_api_authorizations_url,
          state: namespace_project_clusters_url.to_s
        ).authorize_url
    rescue GoogleApi::Auth::ConfigMissingError
      # no-op
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
      render :edit
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
    unless GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
                                           .validate_token(expires_at_in_session)
      redirect_to action: 'login'
    end
  end

  def token_in_session
    @token_in_session ||=
      session[GoogleApi::CloudPlatform::Client.session_key_for_token]
  end

  def expires_at_in_session
    @expires_at_in_session ||=
      session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at]
  end
end
