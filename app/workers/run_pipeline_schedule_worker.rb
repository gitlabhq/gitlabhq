# frozen_string_literal: true

class RunPipelineScheduleWorker
  include ApplicationWorker

  data_consistency :sticky

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_creation
  feature_category :pipeline_composition
  deduplicate :until_executed, including_scheduled: true
  idempotent!

  def perform(schedule_id, user_id, options = {})
    schedule = Ci::PipelineSchedule.find_by_id(schedule_id)
    user = User.find_by_id(user_id)

    return unless schedule_valid?(schedule, schedule_id, user, options)

    update_next_run_at_for(schedule) if options['scheduling']

    response = run_pipeline_schedule(schedule, user)
    log_error(schedule.id, response.message) if response&.error?

    response
  end

  def schedule_valid?(schedule, schedule_id, user, options)
    unless schedule
      log_error(schedule_id, "Schedule not found")
      return false
    end

    unless schedule.project
      log_error(schedule_id, "Project not found for schedule")
      return false
    end

    if schedule.project.self_or_ancestors_archived?
      log_error(schedule_id, "Project or ancestors are archived")
      return false
    end

    if Feature.enabled?(:notify_pipeline_schedule_owner_unavailable,
      user) && schedule_owner_not_available?(schedule)
      log_error(schedule_id, "Pipeline schedule owner is no longer available to schedule the pipeline")
      notify_project_owner_and_deactivate_schedule(schedule)
      return false
    end

    unless user
      log_error(schedule_id, "User not found")
      return false
    end

    if options['scheduling'] && schedule.next_run_at.future?
      log_error(schedule_id, "Schedule next run time is in future")
      return false
    end

    true
  end

  def run_pipeline_schedule(schedule, user)
    Ci::CreatePipelineService
      .new(schedule.project, user, ref: schedule.ref)
      .execute(
        :schedule,
        save_on_errors: true, ignore_skip_ci: true,
        schedule: schedule, inputs: schedule.inputs_hash
      )
  rescue StandardError => e
    error(schedule, e)
  end

  private

  def update_next_run_at_for(schedule)
    # Ensure `next_run_at` is set properly before creating a pipeline.
    # Otherwise, multiple pipelines could be created in a short interval.
    schedule.schedule_next_run!
  end

  def schedule_owner_not_available?(schedule)
    !schedule.owner&.can?(:create_pipeline, schedule.project)
  end

  def notify_project_owner_and_deactivate_schedule(schedule)
    NotificationService.new.pipeline_schedule_owner_unavailable(schedule)
    schedule.deactivate!
  end

  def error(schedule, error)
    failed_creation_counter.increment
    log_error(schedule.id, error.message)
    track_error(schedule, error)
  end

  def log_error(schedule_id, message)
    Gitlab::AppLogger.error "Failed to create a scheduled pipeline. " \
                              "schedule_id: #{schedule_id} message: #{message}"
  end

  def track_error(schedule, error)
    Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
      error,
      issue_url: 'https://gitlab.com/gitlab-org/gitlab-foss/issues/41231',
      schedule_id: schedule.id
    )
  end

  def failed_creation_counter
    @failed_creation_counter ||= Gitlab::Metrics.counter(
      :pipeline_schedule_creation_failed_total,
      "Counter of failed attempts of pipeline schedule creation"
    )
  end
end
