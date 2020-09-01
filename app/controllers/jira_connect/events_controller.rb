# frozen_string_literal: true

class JiraConnect::EventsController < JiraConnect::ApplicationController
  skip_before_action :verify_atlassian_jwt!, only: :installed
  before_action :verify_qsh_claim!, only: :uninstalled

  def installed
    installation = JiraConnectInstallation.new(install_params)

    if installation.save
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def uninstalled
    if current_jira_installation.destroy
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
