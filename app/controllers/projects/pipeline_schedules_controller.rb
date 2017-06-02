class Projects::PipelineSchedulesController < Projects::ApplicationController
  before_action :authorize_read_pipeline_schedule!
  before_action :authorize_create_pipeline_schedule!, only: [:new, :create, :edit, :take_ownership, :update]
  before_action :authorize_admin_pipeline_schedule!, only: [:destroy]

  before_action :schedule, only: [:edit, :update, :destroy, :take_ownership]

  def index
    @scope = params[:scope]
    @all_schedules = PipelineSchedulesFinder.new(@project).execute
    @schedules = PipelineSchedulesFinder.new(@project).execute(scope: params[:scope])
      .includes(:last_pipeline)
  end

  def new
    @schedule = project.pipeline_schedules.new
  end

  def create
    @schedule = Ci::CreatePipelineScheduleService
      .new(@project, current_user, schedule_params)
      .execute

    if @schedule.persisted?
      redirect_to pipeline_schedules_path(@project)
    else
      render :new
    end
  end

  def edit
  end

  def update
    if schedule.update(schedule_params)
      redirect_to namespace_project_pipeline_schedules_path(@project.namespace.becomes(Namespace), @project)
    else
      render :edit
    end
  end

  def take_ownership
    if schedule.update(owner: current_user)
      redirect_to pipeline_schedules_path(@project)
    else
      redirect_to pipeline_schedules_path(@project), alert: "Failed to change the owner"
    end
  end

  def destroy
    if schedule.destroy
      redirect_to pipeline_schedules_path(@project)
    else
      redirect_to pipeline_schedules_path(@project), alert: "Failed to remove the pipeline schedule"
    end
  end

  private

  def schedule
    @schedule ||= project.pipeline_schedules.find(params[:id])
  end

  def schedule_params
    params.require(:schedule)
      .permit(:description, :cron, :cron_timezone, :ref, :active)
  end
end
