class TriggerScheduleWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    Ci::TriggerSchedule.where("next_run_at < ?", Time.now).find_each do |trigger_schedule|
      next if Ci::Pipeline.where(project: trigger_schedule.project, ref: trigger_schedule.ref).running_or_pending.count > 0

      begin
        Ci::CreateTriggerRequestService.new.execute(trigger_schedule.project,
                                                    trigger_schedule.trigger,
                                                    trigger_schedule.ref)
      rescue => e
        puts "#{trigger_schedule.id}: Failed to trigger_schedule job: #{e.message}" # TODO: Remove before merge
        Rails.logger.error "#{trigger_schedule.id}: Failed to trigger_schedule job: #{e.message}"
      ensure
        trigger_schedule.schedule_next_run!
      end
    end
  end
end
