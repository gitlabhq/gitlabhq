# frozen_string_literal: true

class RemoveAiEventsCountAggregationWorkerJobInstances < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  DEPRECATED_JOB_CLASSES = %w[Analytics::AiAnalytics::EventsCountAggregationWorker].freeze
  DEPRECATED_CRON_JOB = 'analytics_refresh_ai_events_counts_cron_worker'

  def up
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
      job_to_remove = Sidekiq::Cron::Job.find(DEPRECATED_CRON_JOB)
      job_to_remove.destroy if job_to_remove
    end

    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end
