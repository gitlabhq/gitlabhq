# frozen_string_literal: true

class Projects::GoogleCloud::BaseController < Projects::ApplicationController
  feature_category :five_minute_production_app

  before_action :admin_project_google_cloud!
  before_action :google_oauth2_enabled!
  before_action :feature_flag_enabled!

  private

  def admin_project_google_cloud!
    access_denied! unless can?(current_user, :admin_project_google_cloud, project)
  end

  def google_oauth2_enabled!
    config = Gitlab::Auth::OAuth::Provider.config_for('google_oauth2')
    if config.app_id.blank? || config.app_secret.blank?
      access_denied! 'This GitLab instance not configured for Google Oauth2.'
    end
  end

  def feature_flag_enabled!
    access_denied! unless Feature.enabled?(:incubation_5mp_google_cloud, project)
  end

  def validate_gcp_token!
    is_token_valid = GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
                                                     .validate_token(expires_at_in_session)

    return if is_token_valid

    return_url = project_google_cloud_index_path(project)
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

  def handle_gcp_error(error, project)
    Gitlab::ErrorTracking.track_exception(error, project_id: project.id)
    @js_data = { screen: 'gcp_error', error: error.to_s }.to_json
    render status: :unauthorized, template: 'projects/google_cloud/errors/gcp_error'
  end
end
