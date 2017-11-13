class Projects::ClustersController < Projects::ApplicationController
  before_action :cluster, except: [:login, :index, :new, :new_gcp, :create]
  before_action :authorize_read_cluster!
  before_action :authorize_create_cluster!, only: [:new, :new_gcp, :create]
  before_action :authorize_google_api, only: [:new_gcp, :create]
  before_action :authorize_update_cluster!, only: [:update]
  before_action :authorize_admin_cluster!, only: [:destroy]

  def index
    if project.cluster
      redirect_to project_cluster_path(project, project.cluster)
    else
      redirect_to new_project_cluster_path(project)
    end
  end

  def login
    begin
      state = generate_session_key_redirect(providers_gcp_new_namespace_project_clusters_url.to_s)

      @authorize_url = GoogleApi::CloudPlatform::Client.new(
        nil, callback_google_api_auth_url,
        state: state).authorize_url
    rescue GoogleApi::Auth::ConfigMissingError
      # no-op
    end
  end

  def new
  end

  def new_gcp
    @cluster = Clusters::Cluster.new.tap do |cluster|
      cluster.build_provider_gcp
    end
  end

  def create
    @cluster = Clusters::CreateService
      .new(project, current_user, create_params)
      .execute(token_in_session)

    if @cluster.persisted?
      redirect_to project_cluster_path(project, @cluster)
    else
      render :new_gcp
    end
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
    @cluster ||= project.cluster.present(current_user: current_user)
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
    params.require(:cluster).permit(:enabled)
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

  def generate_session_key_redirect(uri)
    GoogleApi::CloudPlatform::Client.new_session_key_for_redirect_uri do |key|
      session[key] = uri
    end
  end

  def authorize_update_cluster!
    access_denied! unless can?(current_user, :update_cluster, cluster)
  end

  def authorize_admin_cluster!
    access_denied! unless can?(current_user, :admin_cluster, cluster)
  end
end
