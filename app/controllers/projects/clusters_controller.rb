class Projects::ClustersController < Projects::ApplicationController
  before_action :cluster, except: [:index, :new, :create]
  before_action :authorize_read_cluster!
  before_action :generate_gcp_authorize_url, only: [:new]
  before_action :new_cluster, only: [:new]
  before_action :existing_cluster, only: [:new]
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

  def create
    case params[:type]
    when 'new'
      cluster_params = create_new_cluster_params
    when 'existing'
      cluster_params = create_existing_cluster_params
    end

    @cluster = ::Clusters::CreateService
      .new(project, current_user,  cluster_params)
      .execute(token_in_session)

    if @cluster.persisted?
      redirect_to project_cluster_path(project, @cluster)
    else
      generate_gcp_authorize_url

      case params[:type]
      when 'new'
        @new_cluster = @cluster
        existing_cluster
      when 'existing'
        @existing_cluster = @cluster
        new_cluster
      end

      render :new, locals: { active_tab: params[:type] }
    end
  end

  private

  def cluster
    @cluster ||= project.clusters.find(params[:id])
                                 .present(current_user: current_user)
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

  def create_new_cluster_params
    params.require(:cluster).permit(
      :enabled,
      :name,
      :environment_scope,
      provider_gcp_attributes: [
        :gcp_project_id,
        :zone,
        :num_nodes,
        :machine_type
      ]).merge(
        provider_type: :gcp,
        platform_type: :kubernetes
      )
  end

  def create_existing_cluster_params
    params.require(:cluster).permit(
      :enabled,
      :name,
      :environment_scope,
      platform_kubernetes_attributes: [
        :namespace,
        :api_url,
        :token,
        :ca_cert
      ]).merge(
        provider_type: :user,
        platform_type: :kubernetes
      )
  end

  def generate_gcp_authorize_url
    state = generate_session_key_redirect(new_project_cluster_path(@project).to_s)

    @authorize_url = GoogleApi::CloudPlatform::Client.new(
      nil, callback_google_api_auth_url,
      state: state).authorize_url
  rescue GoogleApi::Auth::ConfigMissingError
    # no-op
  end

  def new_cluster
    if valid_gcp_token
      @new_cluster = ::Clusters::Cluster.new.tap do |cluster|
        cluster.build_provider_gcp
      end
    end
  end

  def existing_cluster
    @existing_cluster = ::Clusters::Cluster.new.tap do |cluster|
      cluster.build_platform_kubernetes
    end
  end

  def valid_gcp_token
    @valid_gcp_token = GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
      .validate_token(expires_at_in_session)
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

  def update_applications_status
    @cluster.applications.each(&:schedule_status_update)
  end
end
