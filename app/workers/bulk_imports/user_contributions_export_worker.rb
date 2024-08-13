# frozen_string_literal: true

module BulkImports
  class UserContributionsExportWorker
    include ApplicationWorker

    idempotent!
    data_consistency :sticky
    feature_category :importers
    worker_resource_boundary :memory

    REENQUEUE_DELAY = 20.seconds
    EXPORT_TIMEOUT = 6.hours

    def perform(portable_id, portable_class, user_id, enqueued_at = nil)
      @portable = portable_class.classify.constantize.find(portable_id)
      @user_id = user_id
      @enqueued_at = enqueued_at || Time.current

      # wait for all other exports to finish so that all contributions will be present
      return log_error('No other exports were created for more than 6 hours') if job_stuck_without_exports?
      return re_enqueue if exports_still_processing?

      UserContributionsExportService.new(@user_id, @portable, @jid).execute
    end

    private

    attr_reader :portable, :user_id, :enqueued_at

    def no_exports?
      portable.bulk_import_exports.empty?
    end

    def job_stuck_without_exports?
      has_been_enqueued_longer_limit = enqueued_at < EXPORT_TIMEOUT.ago
      no_exports? && has_been_enqueued_longer_limit
    end

    def exports_still_processing?
      started_exports = portable.bulk_import_exports.for_status(BulkImports::Export::STARTED)

      started_exports.any?(&:relation_has_user_contributions?) || no_exports?
    end

    def re_enqueue
      self.class.perform_in(REENQUEUE_DELAY, portable.id, portable.class.name, user_id, enqueued_at)
    end

    def log_base_data
      log = { importer: 'gitlab_migration' }
      log.merge!(Gitlab::ImportExport::LogUtil.exportable_to_log_payload(portable))
      log
    end

    def log_error(reason)
      message = "Unable to begin user_contributions export: #{reason}"
      Gitlab::Export::Logger.error(message: message, **log_base_data)
    end
  end
end
