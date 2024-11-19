# frozen_string_literal: true

module BulkImports
  class RelationExportWorker
    include ApplicationWorker
    include ExceptionBacktrace
    include Sidekiq::InterruptionsExhausted

    idempotent!
    deduplicate :until_executed
    loggable_arguments 2, 3
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
          "Export process reached the maximum number of interruptions"
        )
      )
    end

    def self.perform_failure(job, exception)
      user_id, portable_id, portable_type, relation, batched = job['args']
      portable = portable(portable_id, portable_type)
      user = User.find(user_id)

      export = portable.bulk_import_exports.for_user_and_relation(user, relation)

      Gitlab::ErrorTracking.track_exception(exception, portable_id: portable_id, portable_type: portable.class.name)

      export.update!(status_event: 'fail_op', error: exception.message.truncate(255), batched: batched)
    end

    def self.portable(portable_id, portable_class)
      portable_class.classify.constantize.find(portable_id)
    end

    def perform(user_id, portable_id, portable_class, relation, batched = false)
      user = User.find(user_id)
      portable = self.class.portable(portable_id, portable_class)
      config = BulkImports::FileTransfer.config_for(portable)
      log_extra_metadata_on_done(:relation, relation)

      if Gitlab::Utils.to_boolean(batched) && config.batchable_relation?(relation)
        log_extra_metadata_on_done(:batched, true)
        BatchedRelationExportService.new(user, portable, relation, jid).execute
      elsif config.user_contributions_relation?(relation)
        return if Feature.disabled?(:importer_user_mapping, user)

        log_extra_metadata_on_done(:batched, false)
        UserContributionsExportWorker.perform_async(portable_id, portable_class, user_id)
      else
        log_extra_metadata_on_done(:batched, false)
        RelationExportService.new(user, portable, relation, jid).execute
      end
    end
  end
end
