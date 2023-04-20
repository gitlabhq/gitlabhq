# frozen_string_literal: true

module GoogleApi
  class AuthorizationsController < ApplicationController
    include Gitlab::Utils::StrongMemoize

    before_action :validate_session_key!

    feature_category :deployment_management
    urgency :low

    ##
    # handle the response from google after the user
    # goes through authentication and authorization process
    def callback
      redirect_uri = redirect_uri_from_session
      ##
      # when  the user declines authorizations
      # `error` param is returned
      if params[:error]
        flash[:alert] = _('Google Cloud authorizations required')
        redirect_uri = session[:error_uri]
      ##
      # on success, the `code` param is returned
      elsif params[:code]
        token, expires_at = GoogleApi::CloudPlatform::Client
          .new(nil, callback_google_api_auth_url)
          .get_token(params[:code])

        session[GoogleApi::CloudPlatform::Client.session_key_for_token] = token
        session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at] = expires_at.to_s
        redirect_uri = redirect_uri_from_session
      end
    ##
    # or google may just timeout
    rescue ::Faraday::TimeoutError, ::Faraday::ConnectionFailed
      flash[:alert] = _('Timeout connecting to the Google API. Please try again.')
    ##
    # regardless, we redirect the user appropriately
    ensure
      redirect_to redirect_uri
    end

    private

    def validate_session_key!
      access_denied! unless redirect_uri_from_session.present?
    end

    def redirect_uri_from_session
      if params[:state].present?
        session[session_key_for_redirect_uri(params[:state])]
      else
        nil
      end
    end
    strong_memoize_attr :redirect_uri_from_session

    def session_key_for_redirect_uri(state)
      GoogleApi::CloudPlatform::Client.session_key_for_redirect_uri(state)
    end
  end
end
