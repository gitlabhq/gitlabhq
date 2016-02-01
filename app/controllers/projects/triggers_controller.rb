class Projects::TriggersController < Projects::ApplicationController
  before_action :authorize_admin_build!

  layout 'project_settings'

  def index
    @triggers = project.triggers
    @trigger = Ci::Trigger.new
  end

  def create
    @trigger = project.triggers.new
    @trigger.save

    if @trigger.valid?
      redirect_to namespace_project_triggers_path(@project.namespace, @project)
    else
      @triggers = project.triggers.select(&:persisted?)
      render :index
    end
  end

  def destroy
    trigger.destroy

    redirect_to namespace_project_triggers_path(@project.namespace, @project)
  end

  private

  def trigger
    @trigger ||= project.triggers.find(params[:id])
  end
end
