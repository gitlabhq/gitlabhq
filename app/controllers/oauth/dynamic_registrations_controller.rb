# frozen_string_literal: true

module Oauth
  class DynamicRegistrationsController < ApplicationController
    feature_category :system_access

    skip_before_action :authenticate_user!, only: [:create]
    skip_before_action :verify_authenticity_token, only: [:create]
    before_action :check_rate_limit, only: [:create]

    # POST /oauth/register
    def create
      client_metadata = Gitlab::Json.parse(request.body.read).symbolize_keys

      allowed_params = [:redirect_uris, :client_name]

      client_metadata = client_metadata.slice(*allowed_params)

      # Validations here are specific to this controller, not the model
      validation_error = validate_dynamic_fields(client_metadata)
      if validation_error
        render json: validation_error, status: :bad_request
        return
      end

      # All dynamically created OAuth applications can only
      # create mcp scoped access tokens. Disregard any other requests.
      scopes = "mcp"

      redirect_uris = client_metadata[:redirect_uris]
      redirect_uris = [redirect_uris] if redirect_uris.is_a?(String)

      application = ::Authn::OauthApplication.create(
        name: "[Unverified Dynamic Application] #{client_metadata[:client_name]}",
        redirect_uri: Array(redirect_uris).join("\n"),
        scopes: scopes,
        confidential: false,
        dynamic: true
      )

      if application.persisted?
        render json: {
          client_id: application.uid,
          client_id_issued_at: application.created_at.to_i,
          redirect_uris: application.redirect_uri.split("\n"),
          token_endpoint_auth_method: "none",
          grant_types: ["authorization_code"],
          require_pkce: true,
          client_name: application.name,
          scope: scopes,
          dynamic: true
        }, status: :created
      else
        error_message = application.errors.full_messages.join(", ")

        render json: {
          error: "invalid_client_metadata",
          error_description: error_message
        }, status: :bad_request
      end
    end

    private

    def validate_dynamic_fields(client_metadata)
      return if client_metadata[:client_name].present? && (client_metadata[:client_name].length < 200)

      {
        error: "invalid_client_metadata",
        error_description: "client_name is too long"
      }
    end

    def check_rate_limit
      return if Rails.env.test? || Rails.env.development?

      check_rate_limit!(:oauth_dynamic_registration, scope: request.ip)
    end
  end
end
