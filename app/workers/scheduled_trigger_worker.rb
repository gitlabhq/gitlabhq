class ScheduledTriggerWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    # TODO: Update next_run_at

    Ci::ScheduledTriggers.where("next_run_at < ?", Time.now).find_each do |trigger|
      begin
        Ci::CreateTriggerRequestService.new.execute(trigger.project, trigger, trigger.ref)
      rescue => e
        Rails.logger.error "#{trigger.id}: Failed to trigger job: #{e.message}"
      ensure
        trigger.schedule_next_run!
      end
    end
  end
end
