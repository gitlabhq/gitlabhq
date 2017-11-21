class Profiles::SlacksController < Profiles::ApplicationController
  include ServicesHelper

  skip_before_action :authenticate_user!

  layout 'application'

  def edit
    @projects = disabled_projects if current_user
  end

  def slack_link
    project = disabled_projects.find(params[:project_id])
    link = add_to_slack_link(project, current_application_settings.slack_app_id)

    render json: { add_to_slack_link: link }
  end

  private

  def disabled_projects
    @disabled_projects ||= current_user
      .authorized_projects(Gitlab::Access::MASTER)
      .with_slack_application_disabled
  end
end
