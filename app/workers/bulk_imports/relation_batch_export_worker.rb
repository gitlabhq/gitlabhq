# frozen_string_literal: true

module BulkImports
  class RelationBatchExportWorker
    include ApplicationWorker
    include Gitlab::Utils::StrongMemoize
    include Sidekiq::InterruptionsExhausted

    PERFORM_DELAY = 1.minute

    idempotent!
    data_consistency :sticky
    feature_category :importers
    sidekiq_options status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION, retry: 6
    worker_resource_boundary :memory

    sidekiq_retries_exhausted do |job, exception|
      perform_failure(job, exception)
    end

    sidekiq_interruptions_exhausted do |job|
      perform_failure(job,
        Import::Exceptions::SidekiqExhaustedInterruptionsError.new(
          'Export process reached the maximum number of interruptions'
        )
      )
    end

    def self.perform_failure(job, exception)
      batch = BulkImports::ExportBatch.find(job['args'][1])
      portable = batch.export.portable

      Gitlab::ErrorTracking.track_exception(exception, portable_id: portable.id, portable_type: portable.class.name)

      batch.update!(status_event: 'fail_op', error: exception.message.truncate(255))
    end

    def perform(user_id, batch_id)
      @user = User.find(user_id)
      @batch = BulkImports::ExportBatch.find(batch_id)

      return re_enqueue_job(@user, @batch) if !@batch.started? && max_exports_already_running?

      log_extra_metadata_on_done(:relation, @batch.export.relation)
      log_extra_metadata_on_done(:batch_number, @batch.batch_number)

      RelationBatchExportService.new(@user, @batch).execute

      log_extra_metadata_on_done(:objects_count, @batch.objects_count)
    end

    def max_exports_already_running?
      BulkImports::ExportBatch.started_and_not_timed_out.limit(max_exports).count == max_exports
    end

    strong_memoize_attr def max_exports
      ::Gitlab::CurrentSettings.concurrent_relation_batch_export_limit
    end

    def re_enqueue_job(user, batch)
      reset_cache_timeout(batch)
      log_extra_metadata_on_done(:re_enqueue, true)

      self.class.perform_in(PERFORM_DELAY, user.id, batch.id)
    end

    def reset_cache_timeout(batch)
      cache_service = BulkImports::BatchedRelationExportService
      cache_key = cache_service.cache_key(batch.export_id, batch.id)
      Gitlab::Cache::Import::Caching.expire(cache_key, cache_service::CACHE_DURATION.to_i)
    end
  end
end
