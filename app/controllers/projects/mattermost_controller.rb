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
    # Mocking for frontend development
    @teams = [{"id"=>"qz8gdr1fopncueb8n9on8ohk3h", "create_at"=>1479992105904, "update_at"=>1479992105904, "delete_at"=>0, "display_name"=>"chatops", "name"=>"chatops", "email"=>"admin@example.com", "type"=>"O", "company_name"=>"", "allowed_domains"=>"", "invite_id"=>"gthxi47gj7rxtcx6zama63zd1w", "allow_open_invite"=>false}]

    #  @teams =
    #       begin
    #         Mattermost::Mattermost.new(Gitlab.config.mattermost.host, current_user).with_session do
    #          Mattermost::Team.all
    #        end
    #      rescue Mattermost::NoSessionError
    #        @teams = []
    #      end
  end
end
