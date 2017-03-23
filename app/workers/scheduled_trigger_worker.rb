class ScheduledTriggerWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    Ci::ScheduledTrigger.where("next_run_at < ?", Time.now).find_each do |trigger|
      begin
        Ci::CreatePipelineService.new(trigger.project, trigger.owner, ref: trigger.ref).
          execute(ignore_skip_ci: true, scheduled_trigger: true)
      rescue => e
        Rails.logger.error "#{trigger.id}: Failed to trigger job: #{e.message}"
      ensure
        trigger.schedule_next_run!
        trigger.update_last_run!
      end
    end
  end
end
