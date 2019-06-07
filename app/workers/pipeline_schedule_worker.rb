# frozen_string_literal: true

class PipelineScheduleWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    Ci::PipelineSchedule.runnable_schedules.preloaded.find_in_batches do |schedules|
      schedules.each do |schedule|
        Ci::PipelineScheduleService.new(schedule.project, schedule.owner).execute(schedule)
      end
    end
  end
end
