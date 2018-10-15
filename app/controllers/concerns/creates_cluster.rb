# frozen_string_literal: true

module CreatesCluster
  extend ActiveSupport::Concern

  included do
    helper_method :token_in_session
  end

  def new
    render 'shared/clusters/new', locals: {
      gcp_cluster: new_gcp_cluster,
      user_cluster: new_user_cluster,
      authorize_url: generate_gcp_authorize_url,
      valid_gcp_token: validate_gcp_token
    }
  end

  def create_gcp
    gcp_cluster = ::Clusters::CreateService
      .new(current_user, create_gcp_cluster_params)
      .execute(cluster_parent_keyword => cluster_parent, access_token: token_in_session)

    if gcp_cluster.persisted?
      redirect_to cluster_path(gcp_cluster)
    else
      render 'shared/clusters/new', locals: {
        active_tab: 'gcp',
        gcp_cluster: gcp_cluster,
        user_cluster: new_user_cluster,
        authorize_url: generate_gcp_authorize_url,
        valid_gcp_token: validate_gcp_token
      }
    end
  end

  def create_user
    user_cluster = ::Clusters::CreateService
      .new(current_user, create_user_cluster_params)
      .execute(cluster_parent_keyword => cluster_parent, access_token: token_in_session)

    if user_cluster.persisted?
      redirect_to cluster_path(user_cluster)
    else
      render 'shared/clusters/new', locals: {
        active_tab: 'user',
        gcp_cluster: new_gcp_cluster,
        user_cluster: user_cluster,
        authorize_url: generate_gcp_authorize_url,
        valid_gcp_token: validate_gcp_token
      }
    end
  end

  private

  def generate_gcp_authorize_url
    state = generate_session_key_redirect(gcp_authorize_redirect_url.to_s)

    GoogleApi::CloudPlatform::Client.new(
      nil, callback_google_api_auth_url,
      state: state).authorize_url
  rescue GoogleApi::Auth::ConfigMissingError
    # no-op
  end

  def validate_gcp_token
    GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
      .validate_token(expires_at_in_session)
  end

  def new_gcp_cluster
    ::Clusters::Cluster.new.tap do |cluster|
      cluster.build_provider_gcp
    end
  end

  def new_user_cluster
    ::Clusters::Cluster.new.tap do |cluster|
      cluster.build_platform_kubernetes
    end
  end

  def gcp_authorize_redirect_url
    case cluster_parent
    when Project
      new_project_cluster_path(cluster_parent)
    else
      raise "Cannot generate redirect gcp_authorize_redirect_url"
    end
  end

  def cluster_path(cluster)
    case cluster_parent
    when Project
      project_cluster_path(cluster_parent, cluster)
    else
      raise "Unknown cluster_parent type: #{cluster_parent}!"
    end
  end

  def cluster_parent_keyword
    case cluster_parent
    when Project
      :project
    else
      raise "Unknown cluster_parent type: #{cluster_parent}!"
    end
  end

  def token_in_session
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

  def create_gcp_cluster_params
    params.require(:cluster).permit(
      :enabled,
      :name,
      :environment_scope,
      provider_gcp_attributes: [
        :gcp_project_id,
        :zone,
        :num_nodes,
        :machine_type,
        :legacy_abac
      ]).merge(
        provider_type: :gcp,
        platform_type: :kubernetes
      )
  end

  def create_user_cluster_params
    params.require(:cluster).permit(
      :enabled,
      :name,
      :environment_scope,
      platform_kubernetes_attributes: [
        :namespace,
        :api_url,
        :token,
        :ca_cert,
        :authorization_type
      ]).merge(
        provider_type: :user,
        platform_type: :kubernetes
      )
  end
end
