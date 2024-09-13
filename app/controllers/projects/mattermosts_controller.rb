# frozen_string_literal: true

class Projects::MattermostsController < Projects::ApplicationController
  include Ci::TriggersHelper
  include ActionView::Helpers::AssetUrlHelper

  layout 'project_settings'

  before_action :authorize_admin_project!
  before_action :integration
  before_action :teams, only: [:new]

  feature_category :integrations

  def new; end

  def create
    result, message = integration.configure(current_user, configure_params)

    if result
      flash[:notice] = 'This integration is now configured'
      redirect_to edit_project_settings_integration_path(@project, integration)
    else
      flash[:alert] = message || 'Failed to configure integration'
      redirect_to new_project_mattermost_path(@project)
    end
  end

  private

  def configure_params
    params.require(:mattermost).permit(:trigger, :team_id).merge(
      url: integration_trigger_url(integration),
      icon_url: asset_url('slash-command-logo.png', skip_pipeline: true))
  end

  def teams
    @teams, @teams_error_message = integration.list_teams(current_user)
  end

  def integration
    @integration ||= @project.find_or_initialize_integration('mattermost_slash_commands')
  end
end
