# frozen_string_literal: true

module BulkImports
  class UserContributionsExportWorker
    include ApplicationWorker
    include Gitlab::Utils::StrongMemoize

    idempotent!
    data_consistency :sticky
    feature_category :importers
    worker_resource_boundary :memory
    sidekiq_options retry: 6
    sidekiq_options status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION

    sidekiq_retries_exhausted do |job, exception|
      new.perform_failure(job, exception)
    end

    REENQUEUE_DELAY = 20.seconds
    EXPORT_TIMEOUT = 6.hours

    def perform(portable_id, portable_class, user_id, offline_export_id, params = {})
      @portable_id = portable_id
      @portable_class = portable_class
      @user_id = user_id
      @enqueued_at = params['enqueued_at'] || Time.current
      @offline_export_id = offline_export_id

      return if user_contributions_export.completed?

      if job_stuck_without_exports?
        return log_and_fail('Unable to export user_contributions: No other exports were created for more than 6 hours')
      end

      # wait for all other exports to finish so that all contributions will be present
      return re_enqueue if exports_still_processing?

      UserContributionsExportService.new(@user_id, @portable, jid, @offline_export_id).execute
    end

    def perform_failure(job, exception)
      @portable_id, @portable_class, @user_id, @offline_export_id, _params = job['args']

      Gitlab::ErrorTracking.track_exception(
        exception,
        portable_id: @portable_id,
        portable_type: @portable_class,
        offline_export_id: @offline_export_id
      )

      log_and_fail(exception.message.to_s)
    end

    private

    attr_reader :portable_id, :portable_class, :user_id, :enqueued_at, :offline_export_id

    def in_initial_export_state?
      portable.bulk_import_exports
        .for_offline_export(offline_export_id)
        .reject { |export| ignored_relation?(export.relation) }
        .all?(&:pending?)
    end
    strong_memoize_attr :in_initial_export_state?

    def ignored_relation?(relation)
      config = FileTransfer.config_for(portable)
      config.user_contributions_relation?(relation) || config.self_relation?(relation)
    end

    def job_stuck_without_exports?
      has_been_enqueued_longer_limit = enqueued_at < EXPORT_TIMEOUT.ago
      in_initial_export_state? && has_been_enqueued_longer_limit
    end

    def exports_still_processing?
      # The earlier check '#job_stuck_without_exports?' means the export has not hung in initial export state, which
      # if not checked here, would make user contributions begin exporting too soon
      return true if in_initial_export_state?

      in_progress_exports = portable.bulk_import_exports
        .for_offline_export(offline_export_id)
        .for_status(BulkImports::Export::IN_PROGRESS_STATUSES)

      in_progress_exports.any? do |export|
        # Skip over exports that would never have user contributions to export
        next unless export.relation_has_user_contributions?

        # Check that export isn't stale
        export.updated_at > EXPORT_TIMEOUT.ago
      end
    end

    def re_enqueue
      self.class.perform_in(
        REENQUEUE_DELAY,
        portable.id,
        portable.class.name,
        user_id,
        offline_export_id,
        enqueued_at: enqueued_at
      )
    end

    def log_and_fail(message)
      log_error(message)
      user_contributions_export.update!(
        status_event: 'fail_op',
        error: message.truncate(255)
      )
    end

    def portable
      portable_class.classify.constantize.find(portable_id)
    end
    strong_memoize_attr :portable

    def user_contributions_export
      BulkImports::Export.find_or_create_user_contributions_export!(portable, offline_export_id)
    end
    strong_memoize_attr :user_contributions_export

    def log_error(message)
      log_base_data = { importer: 'gitlab_migration', offline_export_id: offline_export_id }
      log_base_data.merge!(Gitlab::ImportExport::LogUtil.exportable_to_log_payload(portable))

      Gitlab::Export::Logger.error(message: message, **log_base_data)
    end
  end
end
