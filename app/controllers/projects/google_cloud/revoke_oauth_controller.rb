# frozen_string_literal: true

class Projects::GoogleCloud::RevokeOauthController < Projects::GoogleCloud::BaseController
  before_action :validate_gcp_token!

  def create
    google_api_client = GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
    response = google_api_client.revoke_authorizations

    if response.success?
      redirect_message = { notice: s_('GoogleCloud|Google OAuth2 token revocation requested') }
      track_event(:revoke_oauth)
    else
      redirect_message = { alert: s_('GoogleCloud|Google OAuth2 token revocation request failed') }
      track_event(:error)
    end

    session.delete(GoogleApi::CloudPlatform::Client.session_key_for_token)

    redirect_to project_google_cloud_configuration_path(project), redirect_message
  end
end
