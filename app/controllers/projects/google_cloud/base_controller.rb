# frozen_string_literal: true

class Projects::GoogleCloud::BaseController < Projects::ApplicationController
  feature_category :five_minute_production_app
  urgency :low

  before_action :admin_project_google_cloud!
  before_action :google_oauth2_enabled!
  before_action :feature_flag_enabled!

  private

  def admin_project_google_cloud!
    unless can?(current_user, :admin_project_google_cloud, project)
      track_event(:error_invalid_user)
      access_denied!
    end
  end

  def google_oauth2_enabled!
    config = Gitlab::Auth::OAuth::Provider.config_for('google_oauth2')
    if config.app_id.blank? || config.app_secret.blank?
      track_event(:error_google_oauth2_not_enabled)
      access_denied! 'This GitLab instance not configured for Google Oauth2.'
    end
  end

  def feature_flag_enabled!
    enabled_for_user = Feature.enabled?(:incubation_5mp_google_cloud, current_user)
    enabled_for_group = Feature.enabled?(:incubation_5mp_google_cloud, project.group)
    enabled_for_project = Feature.enabled?(:incubation_5mp_google_cloud, project)
    feature_is_enabled = enabled_for_user || enabled_for_group || enabled_for_project
    unless feature_is_enabled
      track_event(:error_feature_flag_not_enabled)
      access_denied!
    end
  end

  def validate_gcp_token!
    is_token_valid = GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
                                                     .validate_token(expires_at_in_session)

    return if is_token_valid

    return_url = project_google_cloud_configuration_path(project)
    state = generate_session_key_redirect(request.url, return_url)
    @authorize_url = GoogleApi::CloudPlatform::Client.new(nil,
      callback_google_api_auth_url,
      state: state).authorize_url
    redirect_to @authorize_url
  end

  def generate_session_key_redirect(uri, error_uri)
    GoogleApi::CloudPlatform::Client.new_session_key_for_redirect_uri do |key|
      session[key] = uri
      session[:error_uri] = error_uri
    end
  end

  def token_in_session
    session[GoogleApi::CloudPlatform::Client.session_key_for_token]
  end

  def expires_at_in_session
    session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at]
  end

  def track_event(action, label = nil)
    Gitlab::Tracking.event(
      self.class.name,
      action.to_s,
      label: label,
      project: project,
      user: current_user
    )
  end

  def gcp_projects
    google_api_client = GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
    google_api_client.list_projects
  end

  def refs
    params = { per_page: 50 }
    branches = BranchesFinder.new(project.repository, params).execute(gitaly_pagination: true)
    tags = TagsFinder.new(project.repository, params).execute(gitaly_pagination: true)
    (branches + tags).map(&:name)
  end
end
