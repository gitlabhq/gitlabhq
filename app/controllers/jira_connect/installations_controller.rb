# frozen_string_literal: true

class JiraConnect::InstallationsController < JiraConnect::ApplicationController
  def index
    render json: installation_json(current_jira_installation)
  end

  def update
    result = update_installation
    if result.success?
      render json: installation_json(current_jira_installation)
    else
      render(
        json: { errors: result.message },
        status: :unprocessable_entity
      )
    end
  end

  private

  def update_installation
    JiraConnectInstallations::UpdateService.execute(
      current_jira_installation,
      installation_params
    )
  end

  def installation_json(installation)
    {
      gitlab_com: installation.instance_url.blank?,
      instance_url: installation.instance_url
    }
  end

  def installation_params
    params.require(:installation).permit(:instance_url)
  end
end
