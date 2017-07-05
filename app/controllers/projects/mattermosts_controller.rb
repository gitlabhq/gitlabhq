class Projects::MattermostsController < Projects::ApplicationController
  include TriggersHelper
  include ActionView::Helpers::AssetUrlHelper

  layout 'project_settings'

  before_action :authorize_admin_project!
  before_action :service
  before_action :teams, only: [:new]

  def new
  end

  def create
    result, message = @service.configure(current_user, configure_params)

    if result
      flash[:notice] = 'This service is now configured'
      redirect_to edit_project_service_path(@project, service)
    else
      flash[:alert] = message || 'Failed to configure service'
      redirect_to new_project_mattermost_path(@project)
    end
  end

  private

  def configure_params
    params.require(:mattermost).permit(:trigger, :team_id).merge(
      url: service_trigger_url(@service),
      icon_url: asset_url('slash-command-logo.png'))
  end

  def teams
    @teams, @teams_error_message = @service.list_teams(current_user)
  end

  def service
    @service ||= @project.find_or_initialize_service('mattermost_slash_commands')
  end
end
