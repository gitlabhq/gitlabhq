class Projects::MattermostController < Projects::ApplicationController
  layout 'project_settings'
  before_action :authorize_admin_project!
  before_action :service
  before_action :teams, only: [:new]

  def new
  end

  def configure
    @service.configure(host, current_user, params)

    redirect_to(
      new_namespace_project_service_path(@project.namespace, @project, @service.to_param),
      notice: 'This service is now configured.'
    )
  rescue Mattermost::NoSessionError
    redirect_to(
      edit_namespace_project_service_path(@project.namespace, @project, @service.to_param),
      alert: 'No session could be set up, is Mattermost configured with Single Sign on?'
    )
  end

  private

  def configure_params
    params.require(:configure_params).permit(:trigger, :team_id)
  end

  def service
    @service ||= @project.services.find_by(type: 'MattermostSlashCommandsService')
  end

  def teams
    @teams =
      begin
        Mattermost::Mattermost.new(Gitlab.config.mattermost.host, current_user).with_session do
          Mattermost::Team.team_admin
        end
      rescue Mattermost::NoSessionError
        []
      end
  end
end
