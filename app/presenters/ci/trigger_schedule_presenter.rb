module Ci
  class TriggerSchedulePresenter < Gitlab::View::Presenter::Delegated
    presents :trigger_schedule

    def real_next_run(worker_cron: Settings.cron_jobs['trigger_schedule_worker']['cron'],
                      worker_time_zone: Time.zone.name)
      Gitlab::Ci::CronParser.new(worker_cron, worker_time_zone)
                            .next_time_from(next_run_at)
    end
  end
end
