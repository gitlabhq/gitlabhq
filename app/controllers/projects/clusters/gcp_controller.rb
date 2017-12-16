class Projects::Clusters::GcpController < Projects::ApplicationController
  before_action :authorize_read_cluster!
  before_action :authorize_google_api, except: [:login]
  before_action :authorize_google_project_billing, only: [:check]
  before_action :authorize_create_cluster!, only: [:new, :create]

  STATUS_POLLING_INTERVAL = 1.minute.to_i

  def login
    begin
      state = generate_session_key_redirect(gcp_check_namespace_project_clusters_path.to_s)

      @authorize_url = GoogleApi::CloudPlatform::Client.new(
        nil, callback_google_api_auth_url,
        state: state).authorize_url
    rescue GoogleApi::Auth::ConfigMissingError
      # no-op
    end
  end

  def check
    respond_to do |format|
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: STATUS_POLLING_INTERVAL)

        Gitlab::Redis::SharedState.with do |redis|
          render json: { billing: redis.get(CheckGcpProjectBillingWorker.redis_shared_state_key_for(token_in_session)) }
        end
      end
    end
  end

  def new
    @cluster = ::Clusters::Cluster.new.tap do |cluster|
      cluster.build_provider_gcp
    end
  end

  def create
    @cluster = ::Clusters::CreateService
      .new(project, current_user, create_params)
      .execute(token_in_session)

    if @cluster.persisted?
      redirect_to project_cluster_path(project, @cluster)
    else
      render :new
    end
  end

  private

  def create_params
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

  def authorize_google_api
    unless GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
                                           .validate_token(expires_at_in_session)
      redirect_to action: 'login'
    end
  end

  def authorize_google_project_billing
    Gitlab::Redis::SharedState.with do |redis|
      unless redis.get(CheckGcpProjectBillingWorker.redis_shared_state_key_for(token_in_session)) == 'true'
        CheckGcpProjectBillingWorker.perform_async(token_in_session)
      end
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
end
