class Projects::PipelineSchedulesController < Projects::ApplicationController
  before_action :authorize_create_pipeline!, only: [:new, :create, :edit]
  before_action :authorize_update_pipeline!, only: [:retry, :cancel] # TODO set this right, its own authorize method
  before_action :pipeline_schedule, only: [:edit, :update, :destroy]

  # TODO test for N+1 queries
  def index
    @all_schedules = @project.pipeline_schedules.order('created_at DESC')

    @scope = params[:scope]
    @schedules =
      case @scope
      when 'active'
        @all_schedules.active
      when 'inactive'
        @all_schedules.inactive
      else
        @all_schedules
      end
  end

  def new
    @pipeline_schedule = project.pipeline_schedules.new
  end

  def create
    @pipeline_schedule = Ci::CreatePipelineScheduleService.
      new(@project, current_user, pipeline_schedule_params).
      execute

    if @pipeline_schedule.persisted?
      redirect_to project_pipeline_schedules_path(@project)
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @pipeline_schedule.update_attributes(pipeline_schedule_params).valid?
      redirect_to project_pipeline_schedules_path(@project)
    else
      render :edit
    end
  end

  def destroy
    @pipeline_schedule.destroy
  end

  private

  def pipeline_schedule
    @pipeline_schedule = project.pipeline_schedules.find(params[:id])
  end

  def pipeline_schedule_params
    params.require(:pipeline_schedule).
      permit(:description, :cron, :cron_timezone, :ref).
      reverse_merge(active: true, cron_timezone: 'UTC')
  end
end
