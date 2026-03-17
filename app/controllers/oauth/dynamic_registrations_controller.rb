# frozen_string_literal: true

module Oauth
  class DynamicRegistrationsController < ApplicationController
    feature_category :system_access

    skip_before_action :authenticate_user!, only: [:create]
    skip_before_action :verify_authenticity_token, only: [:create]
    before_action :check_rate_limit, only: [:create]

    RESOURCE_SCOPE_MAP = {
      '/api/v4/orbit/mcp' => Gitlab::Auth::MCP_ORBIT_SCOPE.to_s,
      '/api/v4/mcp' => Gitlab::Auth::MCP_SCOPE.to_s
    }.freeze

    # POST /oauth/register
    def create
      client_metadata = Gitlab::Json.safe_parse(request.body.read).symbolize_keys

      allowed_params = [:redirect_uris, :client_name, :resource]

      client_metadata = client_metadata.slice(*allowed_params)

      # Validations here are specific to this controller, not the model
      validation_error = validate_dynamic_fields(client_metadata)
      if validation_error
        render json: validation_error, status: :bad_request
        return
      end

      # Dynamic apps are restricted to a single MCP scope derived from the
      # resource URL. Any other requested scopes are disregarded.
      scopes = scope_for_resource(client_metadata[:resource])

      redirect_uris = client_metadata[:redirect_uris]
      redirect_uris = [redirect_uris] if redirect_uris.is_a?(String)

      application = ::Authn::OauthApplication.create(
        name: "[Unverified Dynamic Application] #{client_metadata[:client_name]}",
        redirect_uri: Array(redirect_uris).join("\n"),
        scopes: scopes,
        confidential: false,
        dynamic: true,
        organization: Current.organization
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

        render json: error_data(error_message), status: :bad_request
      end
    rescue JSON::ParserError => e
      render json: error_data(e.message), status: :bad_request
    end

    private

    def scope_for_resource(resource)
      return Gitlab::Auth::MCP_SCOPE.to_s if resource.blank?

      RESOURCE_SCOPE_MAP.each do |path, scope|
        return scope if resource.end_with?(path)
      end

      Gitlab::Auth::MCP_SCOPE.to_s
    end

    def validate_dynamic_fields(client_metadata)
      return if client_metadata[:client_name].present? && (client_metadata[:client_name].length < 200)

      error_data("client_name is too long")
    end

    def error_data(error_description)
      {
        error: "invalid_client_metadata",
        error_description: error_description
      }
    end

    def check_rate_limit
      return if Rails.env.test? || Rails.env.development?

      check_rate_limit!(:oauth_dynamic_registration, scope: request.ip)
    end
  end
end
