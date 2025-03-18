# frozen_string_literal: true

class RemoveSearchIndexCurationWorker < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!
  DEPRECATED_JOB_CLASSES = %w[Search::IndexCurationWorker]

  def up
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
      job_to_remove = Sidekiq::Cron::Job.find('search_index_curation_worker')
      job_to_remove.destroy if job_to_remove
      job_to_remove.disable! if job_to_remove
    end

    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down; end
end
