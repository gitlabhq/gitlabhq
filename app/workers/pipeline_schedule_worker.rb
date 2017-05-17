class PipelineScheduleWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    Ci::PipelineSchedule.active.where("next_run_at < ?", Time.now).find_each do |schedule|
      begin
        Ci::CreatePipelineService.new(schedule.project,
                                      schedule.owner,
                                      ref: schedule.ref)
          .execute(save_on_errors: false, schedule: schedule)
      rescue => e
        Rails.logger.error "#{schedule.id}: Failed to create a scheduled pipeline: #{e.message}"
      ensure
        schedule.schedule_next_run!
      end
    end
  end
end
