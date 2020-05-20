# frozen_string_literal: true

module GoogleApi
  class AuthorizationsController < ApplicationController
    include Gitlab::Utils::StrongMemoize

    before_action :validate_session_key!

    def callback
      token, expires_at = GoogleApi::CloudPlatform::Client
        .new(nil, callback_google_api_auth_url)
        .get_token(params[:code])

      session[GoogleApi::CloudPlatform::Client.session_key_for_token] = token
      session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at] =
        expires_at.to_s

    rescue ::Faraday::TimeoutError, ::Faraday::ConnectionFailed
      flash[:alert] = _('Timeout connecting to the Google API. Please try again.')
    ensure
      redirect_to redirect_uri_from_session
    end

    private

    def validate_session_key!
      access_denied! unless redirect_uri_from_session.present?
    end

    def redirect_uri_from_session
      strong_memoize(:redirect_uri_from_session) do
        if params[:state].present?
          session[session_key_for_redirect_uri(params[:state])]
        else
          nil
        end
      end
    end

    def session_key_for_redirect_uri(state)
      GoogleApi::CloudPlatform::Client.session_key_for_redirect_uri(state)
    end
  end
end
