# frozen_string_literal: true

module Import
  module Offline
    class ExportWorker
      include ApplicationWorker

      data_consistency :sticky
      feature_category :importers
      sidekiq_options retry: 3, dead: false
      idempotent!

      sidekiq_retries_exhausted do |msg, exception|
        new.perform_failure(exception, msg['args'].first)
      end

      def perform(offline_export_id)
        offline_export = Import::Offline::Export.find_by_id(offline_export_id)
        return unless offline_export

        Import::Offline::Exports::ProcessService.new(offline_export).execute
      end

      def perform_failure(exception, offline_export_id)
        offline_export = Import::Offline::Export.find_by_id(offline_export_id)

        unless offline_export
          Sidekiq.logger.warn(
            class: self.class.name,
            offline_export_id: offline_export_id,
            message: 'Offline export not found'
          )
          return
        end

        Gitlab::ErrorTracking.track_exception(exception, offline_export_id: offline_export.id)

        offline_export.fail_op!
      end
    end
  end
end
