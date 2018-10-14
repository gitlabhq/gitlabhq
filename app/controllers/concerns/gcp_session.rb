# frozen_string_literal: true

module GcpSession
  extend ActiveSupport::Concern

  included do
    helper_method :gcp_authorize_url
    helper_method :token_in_session
    helper_method :validated_gcp_token
  end

  def gcp_authorize_url(redirect_url)
    state = generate_session_key_redirect(redirect_url.to_s)

    GoogleApi::CloudPlatform::Client.new(
      nil, callback_google_api_auth_url,
      state: state).authorize_url
  rescue GoogleApi::Auth::ConfigMissingError
    # no-op
  end

  def token_in_session
    session[GoogleApi::CloudPlatform::Client.session_key_for_token]
  end

  def validated_gcp_token
    @validated_gcp_token ||= GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
      .validate_token(expires_at_in_session)
  end

  private

  def generate_session_key_redirect(uri)
    GoogleApi::CloudPlatform::Client.new_session_key_for_redirect_uri do |key|
      session[key] = uri
    end
  end

  def expires_at_in_session
    @expires_at_in_session ||=
      session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at]
  end
end
