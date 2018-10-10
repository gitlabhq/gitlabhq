# frozen_string_literal: true

class PipelineScheduleWorker
  include ApplicationWorker
  include CronjobQueue

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    Ci::PipelineSchedule.active.where("next_run_at < ?", Time.now)
      .preload(:owner, :project).find_each do |schedule|
      begin
        pipeline = Ci::CreatePipelineService.new(schedule.project,
                                                 schedule.owner,
                                                 ref: schedule.ref)
          .execute(:schedule, ignore_skip_ci: true, save_on_errors: false, schedule: schedule)

        error(schedule, "Insufficient permissions") unless pipeline.persisted?
      rescue => e
        error(schedule, e.mesasge)
      ensure
        schedule.schedule_next_run!
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def error(schedule, message)
    Rails.logger.error "#{schedule.id}: Failed to create a scheduled pipeline: #{message}"
    failed_creation_counter.increment
  end

  def failed_creation_counter
    @failed_creation_counter ||= Gitlab::Metrics.counter(:pipeline_schedule_creation_failed_total, "Counter of failed attempts of pipeline schedule creation")
  end
end
