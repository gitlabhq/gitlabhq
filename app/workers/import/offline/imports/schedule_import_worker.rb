# frozen_string_literal: true

module Import
  module Offline
    module Imports
      class ScheduleImportWorker
        include ApplicationWorker

        feature_category :importers
        deduplicate :until_executing
        data_consistency :sticky
        sidekiq_options dead: false, retry: 3
        worker_has_external_dependencies!

        idempotent!

        sidekiq_retries_exhausted do |msg, _exception|
          bulk_import = BulkImport.find_by_id(msg['args'].first)
          bulk_import&.fail_op!
        end

        def perform(bulk_import_id, entities)
          bulk_import = BulkImport.find_by_id(bulk_import_id)
          unless bulk_import
            Import::Framework::Logger.warn(class_name: self.class.name, bulk_import_id: bulk_import_id,
              message: 'BulkImport not found')
            return
          end

          unless bulk_import.created?
            Import::Framework::Logger.warn(class_name: self.class.name, bulk_import_id: bulk_import_id,
              message: 'BulkImport is not in created state')
            return
          end

          unless bulk_import.offline_configuration.present?
            Import::Framework::Logger.warn(class_name: self.class.name, bulk_import_id: bulk_import_id,
              message: 'Offline configuration not found')
            bulk_import.fail_op!
            return
          end

          ScheduleImportService.new(bulk_import, entities).execute
        end
      end
    end
  end
end
