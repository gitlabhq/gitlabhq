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
    return if request.format.json? && jwt.verify_context_qsh_claim

    # Make sure `qsh` claim matches the current request
    render_403 unless jwt.verify_qsh_claim(request.url, request.method, jira_connect_base_url)
  end

  def atlassian_jwt_valid?
    return false unless installation_from_jwt

    # Verify JWT signature with our stored `shared_secret`
    jwt.valid?(installation_from_jwt.shared_secret)
  end

  def installation_from_jwt
    strong_memoize(:installation_from_jwt) do
      next unless jwt.iss_claim

      JiraConnectInstallation.find_by_client_key(jwt.iss_claim)
    end
  end

  def jira_user
    strong_memoize(:jira_user) do
      next unless installation_from_jwt
      next unless jwt.sub_claim

      # This only works for Jira Cloud installations.
      installation_from_jwt.client.user_info(jwt.sub_claim)
    end
  end

  def jwt
    strong_memoize(:jwt) do
      Atlassian::JiraConnect::Jwt::Symmetric.new(auth_token)
    end
  end

  def auth_token
    params[:jwt] || request.headers['Authorization']&.split(' ', 2)&.last
  end
end

JiraConnect::ApplicationController.prepend_mod
