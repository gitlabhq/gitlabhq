# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class CleanupTerminatedBulkImportConfigs < BatchedMigrationJob
      operation_name :cleanup_terminated_bulk_import_configs

      class BulkImport < ::ApplicationRecord
        self.table_name = 'bulk_imports'

        has_one :configuration, class_name: 'BulkImportConfiguration'
      end

      class BulkImportConfiguration < ::ApplicationRecord
        self.table_name = 'bulk_import_configurations'
        belongs_to :bulk_import
      end

      # rubocop:disable Database/AvoidScopeTo -- supporting index: index_bulk_imports_on_terminated_status
      scope_to ->(relation) { relation.where(status: [2, 3, -1, -2]) }
      # rubocop:enable Database/AvoidScopeTo

      feature_category :importers

      def perform
        each_sub_batch do |sub_batch|
          configurations_to_delete = BulkImportConfiguration.where(bulk_import_id: sub_batch.pluck(:id))
          configurations_to_delete.delete_all
        end
      end
    end
  end
end
