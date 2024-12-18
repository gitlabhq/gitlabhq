# frozen_string_literal: true

class CleanupCodeSuggestionEventsRetries < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.7'

  WORKER_CLASS = 'ClickHouse::CodeSuggestionEventsCronWorker'

  def up
    # TODO: make shard-aware. See https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/3430
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
      Sidekiq::Cron::Job.destroy('click_house_code_suggestion_events_cron_worker')
    end

    sidekiq_remove_jobs(job_klasses: [WORKER_CLASS])
  end

  def down
    # no-op
  end
end
