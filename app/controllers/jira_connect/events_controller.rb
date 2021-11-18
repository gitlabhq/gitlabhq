# frozen_string_literal: true

class JiraConnect::EventsController < JiraConnect::ApplicationController
  # See https://developer.atlassian.com/cloud/jira/software/app-descriptor/#lifecycle

  skip_before_action :verify_atlassian_jwt!
  before_action :verify_asymmetric_atlassian_jwt!

  def installed
    return head :ok if current_jira_installation

    installation = JiraConnectInstallation.new(event_params)

    if installation.save
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def uninstalled
    if JiraConnectInstallations::DestroyService.execute(current_jira_installation, jira_connect_base_path, jira_connect_events_uninstalled_path)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def event_params
    params.permit(:clientKey, :sharedSecret, :baseUrl).transform_keys(&:underscore)
  end

  def verify_asymmetric_atlassian_jwt!
    asymmetric_jwt = Atlassian::JiraConnect::AsymmetricJwt.new(auth_token, jwt_verification_claims)

    return head :unauthorized unless asymmetric_jwt.valid?

    @current_jira_installation = JiraConnectInstallation.find_by_client_key(asymmetric_jwt.iss_claim)
  end

  def jwt_verification_claims
    {
      aud: jira_connect_base_url(protocol: 'https'),
      iss: event_params[:client_key],
      qsh: Atlassian::Jwt.create_query_string_hash(request.url, request.method, jira_connect_base_url)
    }
  end
end
