# frozen_string_literal: true

class JiraConnect::InstallationsController < JiraConnect::ApplicationController
  def index
    render json: installation_json(current_jira_installation)
  end

  def update
    return render_forbidden unless jira_user

    result = update_installation
    if result.success?
      render json: installation_json(current_jira_installation)
    elsif result.reason == :forbidden
      render_forbidden
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
      jira_user,
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
    params
      .require(:installation)
      .permit(:instance_url)
      .merge(organization_id: Current.organization.id)
  end

  def render_forbidden
    render(
      json: {
        errors: s_('JiraConnect|The Jira user is not a site or organization administrator. ' \
          'Check the permissions in Jira and try again.')
      },
      status: :forbidden
    )
  end
end
