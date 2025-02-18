# frozen_string_literal: true

class Projects::PipelineSchedulesController < Projects::ApplicationController
  before_action :schedule, except: [:index, :new, :create]

  before_action :check_play_rate_limit!, only: [:play]
  before_action :authorize_play_pipeline_schedule!, only: [:play]
  before_action :authorize_read_pipeline_schedule!
  before_action :authorize_create_pipeline_schedule!, only: [:new, :create]
  before_action :authorize_update_pipeline_schedule!, only: [:edit, :update]
  before_action :authorize_admin_pipeline_schedule!, only: [:take_ownership, :destroy]

  feature_category :continuous_integration
  urgency :low

  def index
    @scope = params[:scope]
    @all_schedules = Ci::PipelineSchedulesFinder.new(@project).execute
    @schedules = Ci::PipelineSchedulesFinder.new(@project).execute(scope: params[:scope])
  end

  def new; end

  def create
    response = Ci::PipelineSchedules::CreateService.new(@project, current_user, schedule_params).execute
    @schedule = response.payload

    if response.success?
      redirect_to pipeline_schedules_path(@project)
    else
      render :new
    end
  end

  def edit; end

  def update
    response = Ci::PipelineSchedules::UpdateService.new(schedule, current_user, schedule_params).execute

    if response.success?
      redirect_to project_pipeline_schedules_path(@project)
    else
      render :edit
    end
  end

  def play
    job_id = Ci::PipelineSchedules::PlayService
              .new(schedule.project, current_user)
              .execute(schedule)

    if job_id
      pipelines_link_start = "<a href=\"#{project_pipelines_path(@project)}\">"
      message = _("Successfully scheduled a pipeline to run. Go to the %{pipelines_link_start}Pipelines page%{pipelines_link_end} for details.") % { pipelines_link_start: pipelines_link_start, pipelines_link_end: "</a>" }
      flash[:notice] = message.html_safe
    else
      flash[:alert] = _('Unable to schedule a pipeline to run immediately')
    end

    redirect_to pipeline_schedules_path(@project)
  end

  def take_ownership
    response = Ci::PipelineSchedules::TakeOwnershipService.new(schedule, current_user).execute

    if response.success?
      redirect_to pipeline_schedules_path(@project)
    else
      redirect_to pipeline_schedules_path(@project), alert: _("Failed to change the owner")
    end
  end

  def destroy
    if schedule.destroy
      redirect_to pipeline_schedules_path(@project), status: :found
    else
      redirect_to pipeline_schedules_path(@project), status: :forbidden, alert: _("Failed to remove the pipeline schedule")
    end
  end

  private

  def check_play_rate_limit!
    return unless current_user

    check_rate_limit!(:play_pipeline_schedule, scope: [current_user, schedule]) do
      flash[:alert] = _('You cannot play this scheduled pipeline at the moment. Please wait a minute.')
      redirect_to pipeline_schedules_path(@project)
    end
  end

  def schedule
    @schedule ||= project.pipeline_schedules.find(params[:id])
  end

  def schedule_params
    params.require(:schedule)
      .permit(:description, :cron, :cron_timezone, :ref, :active,
        variables_attributes: [:id, :variable_type, :key, :secret_value, :_destroy])
  end

  def new_schedule
    # We need the `ref` here for `authorize_create_pipeline_schedule!`
    @schedule ||= project.pipeline_schedules.new(ref: params.dig(:schedule, :ref))
  end

  def authorize_create_pipeline_schedule!
    access_denied! unless can?(current_user, :create_pipeline_schedule, new_schedule)
  end

  def authorize_play_pipeline_schedule!
    access_denied! unless can?(current_user, :play_pipeline_schedule, schedule)
  end

  def authorize_update_pipeline_schedule!
    access_denied! unless can?(current_user, :update_pipeline_schedule, schedule)
  end

  def authorize_admin_pipeline_schedule!
    access_denied! unless can?(current_user, :admin_pipeline_schedule, schedule)
  end
end
