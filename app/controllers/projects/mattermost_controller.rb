class Projects::MattermostController < Projects::ApplicationController
  layout 'project_settings'
  before_action :authorize_admin_project!
  before_action :service
  before_action :teams, only: [:new]

  def new
  end

  def create
    message = @service.configure(current_user, configure_params)
    notice = message.is_a?(String) ? message : 'This service is now configured'

    redirect_to(
      new_namespace_project_mattermost_path(@project.namespace, @project),
      notice: notice
    )
  rescue NoSessionError
    redirect_to(
      new_namespace_project_mattermost_path(@project.namespace, @project),
      alert: 'No session could be set up, is Mattermost configured with Single Sign on?'
    )
  end

  private

  def configure_params
    params.permit(:trigger, :team_id).
      merge(url: service_trigger_url(@service), icon_url: asset_url('gitlab_logo.png'))
  end

  def service
    @service ||= @project.find_or_initialize_service('mattermost_slash_commands')
  end

  def teams
    @teams = @service.list_teams(current_user)
  end
end
