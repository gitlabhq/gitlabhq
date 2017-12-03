class RunPipelineScheduleWorker
  include Sidekiq::Worker
  include PipelineQueue

  enqueue_in group: :creation

  def perform(schedule_id, user_id)
    schedule = Ci::PipelineSchedule.find(schedule_id)
    user = User.find(user_id)

    run_pipeline_schedule(schedule, user)
  end

  def run_pipeline_schedule(schedule, user)
    Ci::CreatePipelineService.new(schedule.project,
                                  user,
                                  ref: schedule.ref)
      .execute(:schedule, ignore_skip_ci: true, save_on_errors: false, schedule: schedule)
  end
end
