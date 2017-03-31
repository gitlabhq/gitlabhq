module TriggersHelper
  def builds_trigger_url(project_id, ref: nil)
    if ref.nil?
      "#{Settings.gitlab.url}/api/v4/projects/#{project_id}/trigger/pipeline"
    else
      "#{Settings.gitlab.url}/api/v4/projects/#{project_id}/ref/#{ref}/trigger/pipeline"
    end
  end

  def service_trigger_url(service)
    "#{Settings.gitlab.url}/api/v3/projects/#{service.project_id}/services/#{service.to_param}/trigger"
  end

  def real_next_run(trigger_schedule, worker_cron: nil, worker_time_zone: nil)
    worker_cron = Settings.cron_jobs['trigger_schedule_worker']['cron'] unless worker_cron.present?
    worker_time_zone = Time.zone.name unless worker_time_zone.present?

    worker_next_time = Ci::CronParser.new(worker_cron, worker_time_zone).next_time_from(Time.now)

    if trigger_schedule.next_run_at > worker_next_time
      trigger_schedule.next_run_at
    else
      worker_next_time
    end
  end
end
