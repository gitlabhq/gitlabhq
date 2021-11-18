# frozen_string_literal: true

class JiraConnect::ApplicationController < ApplicationController
  include Gitlab::Utils::StrongMemoize

  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  before_action :verify_atlassian_jwt!

  feature_category :integrations

  attr_reader :current_jira_installation

  private

  def verify_atlassian_jwt!
    return render_403 unless atlassian_jwt_valid?

    @current_jira_installation = installation_from_jwt
  end

  def verify_qsh_claim!
    payload, _ = decode_auth_token!

    # Make sure `qsh` claim matches the current request
    render_403 unless payload['qsh'] == Atlassian::Jwt.create_query_string_hash(request.url, request.method, jira_connect_base_url)
  rescue StandardError
    render_403
  end

  def atlassian_jwt_valid?
    return false unless installation_from_jwt

    # Verify JWT signature with our stored `shared_secret`
    decode_auth_token!
  rescue JWT::DecodeError
    false
  end

  def installation_from_jwt
    strong_memoize(:installation_from_jwt) do
      next unless claims['iss']

      JiraConnectInstallation.find_by_client_key(claims['iss'])
    end
  end

  def claims
    strong_memoize(:claims) do
      next {} unless auth_token

      # Decode without verification to get `client_key` in `iss`
      payload, _ = Atlassian::Jwt.decode(auth_token, nil, false)
      payload
    end
  end

  def jira_user
    strong_memoize(:jira_user) do
      next unless installation_from_jwt
      next unless claims['sub']

      # This only works for Jira Cloud installations.
      installation_from_jwt.client.user_info(claims['sub'])
    end
  end

  def decode_auth_token!
    Atlassian::Jwt.decode(auth_token, installation_from_jwt.shared_secret)
  end

  def auth_token
    strong_memoize(:auth_token) do
      params[:jwt] || request.headers['Authorization']&.split(' ', 2)&.last
    end
  end
end
