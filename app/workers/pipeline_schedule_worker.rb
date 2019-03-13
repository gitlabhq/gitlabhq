# frozen_string_literal: true

class PipelineScheduleWorker
  include ApplicationWorker
  include CronjobQueue

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    Ci::PipelineSchedule.active.where("next_run_at < ?", Time.now)
      .preload(:owner, :project).find_each do |schedule|

      Ci::CreatePipelineService.new(schedule.project,
                                    schedule.owner,
                                    ref: schedule.ref)
        .execute!(:schedule, ignore_skip_ci: true, save_on_errors: true, schedule: schedule)
    rescue => e
      error(schedule, e)
    ensure
      schedule.schedule_next_run!
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def error(schedule, error)
    failed_creation_counter.increment

    Rails.logger.error "Failed to create a scheduled pipeline. " \
                       "schedule_id: #{schedule.id} message: #{error.message}"

    Gitlab::Sentry
      .track_exception(error,
                       issue_url: 'https://gitlab.com/gitlab-org/gitlab-ce/issues/41231',
                       extra: { schedule_id: schedule.id })
  end

  def failed_creation_counter
    @failed_creation_counter ||=
      Gitlab::Metrics.counter(:pipeline_schedule_creation_failed_total,
                              "Counter of failed attempts of pipeline schedule creation")
  end
end
