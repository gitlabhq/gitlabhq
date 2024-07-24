# frozen_string_literal: true

class RemovePackagesComposerCacheFileWorkers < Gitlab::Database::Migration[2.2]
  DEPRECATED_JOB_CLASSES = %w[
    Packages::Composer::CacheCleanupWorker
    Packages::Composer::CacheUpdateWorker
  ]

  disable_ddl_transaction!
  milestone '17.3'

  def up
    # The job has been scheduled via sidekiq-cron, so we are removing
    # it from the scheduled worker using the keys removed from 1_settings.rb
    # in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71230
    #
    # TODO: make shard-aware. See https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/3430
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
      job_to_remove = Sidekiq::Cron::Job.find('packages_composer_cache_cleanup_worker')
      job_to_remove.destroy if job_to_remove
      job_to_remove.disable! if job_to_remove
    end

    # Removes scheduled instances from Sidekiq queues
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end
