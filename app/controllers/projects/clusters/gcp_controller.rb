class Projects::Clusters::GcpController < Projects::ApplicationController
  before_action :authorize_read_cluster!
  before_action :authorize_google_api, except: [:login]
  before_action :authorize_google_project_billing, only: [:new, :create]
  before_action :authorize_create_cluster!, only: [:new, :create]
  before_action :verify_billing, only: [:create]

  def login
    begin
      state = generate_session_key_redirect(gcp_new_namespace_project_clusters_path.to_s)

      @authorize_url = GoogleApi::CloudPlatform::Client.new(
        nil, callback_google_api_auth_url,
        state: state).authorize_url
    rescue GoogleApi::Auth::ConfigMissingError
      # no-op
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

  def verify_billing
    case google_project_billing_status
    when nil
      flash.now[:alert] = _('We could not verify that one of your projects on GCP has billing enabled. Please try again.')
    when false
      flash.now[:alert] = _('Please <a href=%{link_to_billing} target="_blank" rel="noopener noreferrer">enable billing for one of your projects to be able to create a Kubernetes cluster</a>, then try again.').html_safe % { link_to_billing: "https://console.cloud.google.com/freetrial?utm_campaign=2018_cpanel&utm_source=gitlab&utm_medium=referral" }
    when true
      return
    end

    @cluster = ::Clusters::Cluster.new(create_params)

    render :new
  end

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
    redis_token_key = CheckGcpProjectBillingWorker.store_session_token(token_in_session)
    CheckGcpProjectBillingWorker.perform_async(redis_token_key)
  end

  def google_project_billing_status
    CheckGcpProjectBillingWorker.get_billing_state(token_in_session)
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
