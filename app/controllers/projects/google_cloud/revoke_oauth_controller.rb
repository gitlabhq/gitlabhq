# frozen_string_literal: true

class Projects::GoogleCloud::RevokeOauthController < Projects::GoogleCloud::BaseController
  before_action :validate_gcp_token!

  def create
    google_api_client = GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
    response = google_api_client.revoke_authorizations

    if response.success?
      status = 'success'
      redirect_message = { notice: s_('GoogleCloud|Google OAuth2 token revocation requested') }
    else
      status = 'failed'
      redirect_message = { alert: s_('GoogleCloud|Google OAuth2 token revocation request failed') }
    end

    session.delete(GoogleApi::CloudPlatform::Client.session_key_for_token)
    track_event('revoke_oauth#create', 'create', status)

    redirect_to project_google_cloud_index_path(project), redirect_message
  end
end
