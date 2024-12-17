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

    return unless schedule && schedule.project && user

    options.symbolize_keys!

    if options[:scheduling]
      return if schedule.next_run_at.future?

      update_next_run_at_for(schedule)
    end

    run_pipeline_schedule(schedule, user)
  end

  def run_pipeline_schedule(schedule, user)
    Ci::CreatePipelineService
      .new(schedule.project, user, ref: schedule.ref)
      .execute(
        :schedule,
        save_on_errors: true,
        ignore_skip_ci: true, schedule: schedule
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

  def error(schedule, error)
    failed_creation_counter.increment
    log_error(schedule, error)
    track_error(schedule, error)
  end

  def log_error(schedule, error)
    Gitlab::AppLogger.error "Failed to create a scheduled pipeline. " \
                       "schedule_id: #{schedule.id} message: #{error.message}"
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
