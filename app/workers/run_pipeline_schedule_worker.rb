class RunPipelineScheduleWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_creation

  def perform(schedule_id, user_id)
    schedule = Ci::PipelineSchedule.find_by(id: schedule_id)
    user = User.find_by(id: user_id)

    return unless schedule && user

    run_pipeline_schedule(schedule, user)
  end

  def run_pipeline_schedule(schedule, user)
    Ci::CreatePipelineService.new(schedule.project,
                                  user,
                                  ref: schedule.ref)
      .execute(:schedule, ignore_skip_ci: true, save_on_errors: false, schedule: schedule)
  end
end
