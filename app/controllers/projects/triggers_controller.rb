class Projects::TriggersController < Projects::ApplicationController
  before_action :ci_project
  before_action :authorize_admin_project!

  layout 'project_settings'

  def index
    @triggers = @ci_project.triggers
    @trigger = Ci::Trigger.new
  end

  def create
    @trigger = @ci_project.triggers.new
    @trigger.save

    if @trigger.valid?
      redirect_to namespace_project_triggers_path(@project.namespace, @project)
    else
      @triggers = @ci_project.triggers.select(&:persisted?)
      render :index
    end
  end

  def destroy
    trigger.destroy

    redirect_to namespace_project_triggers_path(@project.namespace, @project)
  end

  private

  def trigger
    @trigger ||= @ci_project.triggers.find(params[:id])
  end
end
