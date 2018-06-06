module ClustersHelper
  def has_multiple_clusters?(project)
    false
  end

  def render_gcp_signup_offer
    return unless show_gcp_signup_offer?

    content_tag :section, class: 'no-animate expanded' do
      render 'projects/clusters/gcp_signup_offer_banner'
    end
  end

  def gcp_cluster
    @gcp_cluster = ::Clusters::Cluster.new.tap do |cluster|
      cluster.build_provider_gcp
    end
  end

  def user_cluster
    @user_cluster = ::Clusters::Cluster.new.tap do |cluster|
      cluster.build_platform_kubernetes
    end
  end

  def gcp_authorize_url
    state = generate_session_key_redirect(new_project_cluster_path(@project).to_s)

    GoogleApi::CloudPlatform::Client.new(
      nil, callback_google_api_auth_url,
      state: state).authorize_url
  rescue GoogleApi::Auth::ConfigMissingError
    # no-op
  end

  def generate_session_key_redirect(uri)
    GoogleApi::CloudPlatform::Client.new_session_key_for_redirect_uri do |key|
      session[key] = uri
    end
  end

  def token_in_session
    session[GoogleApi::CloudPlatform::Client.session_key_for_token]
  end

  def expires_at_in_session
    @expires_at_in_session ||=
      session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at]
  end

  def valid_gcp_token
    GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
      .validate_token(expires_at_in_session)
  end
end
