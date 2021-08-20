# frozen_string_literal: true

class JiraConnect::InstallationsController < JiraConnect::ApplicationController
  def index
    render json: installation_json(current_jira_installation)
  end

  def update
    if current_jira_installation.update(installation_params)
      render json: installation_json(current_jira_installation)
    else
      render(
        json: { errors: current_jira_installation.errors },
        status: :unprocessable_entity
      )
    end
  end

  private

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
