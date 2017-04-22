class Projects::PipelineSchedulesController < Projects::ApplicationController
  before_action :authorize_read_pipeline!
  before_action :authorize_create_pipeline!, only: [:new, :create, :edit, :take_ownership]
  before_action :authorize_admin_pipeline!, only: [:destroy]

  before_action :pipeline_schedule, only: [:edit, :update, :destroy, :take_ownership]

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
    @timezones = TZInfo::Timezone.all.json

    @pipeline_schedule = Ci::CreatePipelineScheduleService.
      new(@project, current_user, pipeline_schedule_params).
      execute

    if @pipeline_schedule.persisted?
      redirect_to pipeline_schedules_path(@project)
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @pipeline_schedule.update(pipeline_schedule_params)
      redirect_to pipeline_schedules_path(@project)
    else
      render :edit
    end
  end

  def take_ownership
    @pipeline_schedule.own!(current_user)

    redirect_to pipeline_schedules_path(@project)
  end

  def destroy
    @pipeline_schedule.destroy

    redirect_to pipeline_schedules_path(@project)
  end

  private

  def pipeline_schedule
    @pipeline_schedule = project.pipeline_schedules.find(params[:id])
  end

  def pipeline_schedule_params
    params.require(:pipeline_schedule).
      permit(:description, :cron, :cron_timezone, :ref, :active)
  end
end
