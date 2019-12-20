# frozen_string_literal: true

class RunPipelineScheduleWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_creation
  feature_category :continuous_integration

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(schedule_id, user_id)
    schedule = Ci::PipelineSchedule.find_by(id: schedule_id)
    user = User.find_by(id: user_id)

    return unless schedule && user

    run_pipeline_schedule(schedule, user)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def run_pipeline_schedule(schedule, user)
    Ci::CreatePipelineService.new(schedule.project,
                                  user,
                                  ref: schedule.ref)
      .execute!(:schedule, ignore_skip_ci: true, save_on_errors: false, schedule: schedule)
  rescue Ci::CreatePipelineService::CreateError
    # no-op. This is a user operation error such as corrupted .gitlab-ci.yml.
  rescue => e
    error(schedule, e)
  end

  private

  # rubocop:disable Gitlab/RailsLogger
  def error(schedule, error)
    failed_creation_counter.increment

    Rails.logger.error "Failed to create a scheduled pipeline. " \
                       "schedule_id: #{schedule.id} message: #{error.message}"

    Gitlab::ErrorTracking
      .track_and_raise_for_dev_exception(error,
                       issue_url: 'https://gitlab.com/gitlab-org/gitlab-foss/issues/41231',
                       schedule_id: schedule.id)
  end
  # rubocop:enable Gitlab/RailsLogger

  def failed_creation_counter
    @failed_creation_counter ||=
      Gitlab::Metrics.counter(:pipeline_schedule_creation_failed_total,
                              "Counter of failed attempts of pipeline schedule creation")
  end
end
