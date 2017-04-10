class TriggerScheduleWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    Ci::TriggerSchedule.active.where("next_run_at < ?", Time.now).find_each do |trigger_schedule|
      begin
        Ci::CreateTriggerRequestService.new.execute(trigger_schedule.project,
                                                    trigger_schedule.trigger,
                                                    trigger_schedule.ref)
      rescue => e
        Rails.logger.error "#{trigger_schedule.id}: Failed to trigger_schedule job: #{e.message}"
      ensure
        trigger_schedule.schedule_next_run!
      end
    end
  end
end
