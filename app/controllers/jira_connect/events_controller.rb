# frozen_string_literal: true

class JiraConnect::EventsController < JiraConnect::ApplicationController
  # See https://developer.atlassian.com/cloud/jira/software/app-descriptor/#lifecycle

  skip_before_action :verify_atlassian_jwt!, only: :installed
  before_action :verify_qsh_claim!, only: :uninstalled

  def installed
    return head :ok if atlassian_jwt_valid?

    installation = JiraConnectInstallation.new(install_params)

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

  def install_params
    params.permit(:clientKey, :sharedSecret, :baseUrl).transform_keys(&:underscore)
  end
end
