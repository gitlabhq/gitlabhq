class Projects::TriggersController < Projects::ApplicationController
  before_action :authorize_admin_build!

  layout 'project_settings'

  def index
    redirect_to namespace_project_settings_ci_cd_path(@project.namespace, @project)
  end

  def create
    @trigger = project.triggers.new
    @trigger.save

    if @trigger.valid?
      flash[:notice] = "Trigger has been created successfully"
    else
      @triggers = project.triggers.select(&:persisted?)
    end
    redirect_to namespace_project_settings_ci_cd_path(@project.namespace, @project)
  end

  def destroy
    trigger.destroy
    flash[:alert] = "Trigger removed"

    redirect_to namespace_project_settings_ci_cd_path(@project.namespace, @project)
  end

  private

  def trigger
    @trigger ||= project.triggers.find(params[:id])
  end
end
