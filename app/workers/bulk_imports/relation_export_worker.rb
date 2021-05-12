# frozen_string_literal: true

module BulkImports
  class RelationExportWorker
    include ApplicationWorker
    include ExceptionBacktrace

    idempotent!
    loggable_arguments 2, 3
    feature_category :importers
    tags :exclude_from_kubernetes
    sidekiq_options status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION

    def perform(user_id, portable_id, portable_class, relation)
      user = User.find(user_id)
      portable = portable(portable_id, portable_class)

      RelationExportService.new(user, portable, relation, jid).execute
    end

    private

    def portable(portable_id, portable_class)
      portable_class.classify.constantize.find(portable_id)
    end
  end
end
