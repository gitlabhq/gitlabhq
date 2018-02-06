class Projects::PipelineSchedulesController < Projects::ApplicationController
  before_action :schedule, except: [:index, :new, :create]

  before_action :play_rate_limit, only: [:play]
  before_action :authorize_play_pipeline_schedule!, only: [:play]
  before_action :authorize_read_pipeline_schedule!
  before_action :authorize_create_pipeline_schedule!, only: [:new, :create]
  before_action :authorize_update_pipeline_schedule!, except: [:index, :new, :create, :play]
  before_action :authorize_admin_pipeline_schedule!, only: [:destroy]

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
      redirect_to project_pipeline_schedules_path(@project)
    else
      render :edit
    end
  end

  def play
    job_id = RunPipelineScheduleWorker.perform_async(schedule.id, current_user.id)

    if job_id
      flash[:notice] = "Successfully scheduled a pipeline to run. Go to the <a href=\"#{project_pipelines_path(@project)}\">Pipelines page</a> for details.".html_safe
    else
      flash[:alert] = 'Unable to schedule a pipeline to run immediately'
    end

    redirect_to pipeline_schedules_path(@project)
  end

  def take_ownership
    if schedule.update(owner: current_user)
      redirect_to pipeline_schedules_path(@project)
    else
      redirect_to pipeline_schedules_path(@project), alert: _("Failed to change the owner")
    end
  end

  def destroy
    if schedule.destroy
      redirect_to pipeline_schedules_path(@project), status: 302
    else
      redirect_to pipeline_schedules_path(@project),
                  status: :forbidden,
                  alert: _("Failed to remove the pipeline schedule")
    end
  end

  private

  def play_rate_limit
    return unless current_user

    limiter = ::Gitlab::ActionRateLimiter.new(action: :play_pipeline_schedule)

    return unless limiter.throttled?([current_user, schedule], 1)

    flash[:alert] = 'You cannot play this scheduled pipeline at the moment. Please wait a minute.'
    redirect_to pipeline_schedules_path(@project)
  end

  def schedule
    @schedule ||= project.pipeline_schedules.find(params[:id])
  end

  def schedule_params
    params.require(:schedule)
      .permit(:description, :cron, :cron_timezone, :ref, :active,
        variables_attributes: [:id, :key, :value, :_destroy] )
  end

  def authorize_play_pipeline_schedule!
    return access_denied! unless can?(current_user, :play_pipeline_schedule, schedule)
  end

  def authorize_update_pipeline_schedule!
    return access_denied! unless can?(current_user, :update_pipeline_schedule, schedule)
  end

  def authorize_admin_pipeline_schedule!
    return access_denied! unless can?(current_user, :admin_pipeline_schedule, schedule)
  end
end
