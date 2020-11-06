# frozen_string_literal: true

module BulkImports
  module Importers
    class GroupsImporter
      def initialize(bulk_import_id)
        @bulk_import = BulkImport.find(bulk_import_id)
      end

      def execute
        bulk_import.start! unless bulk_import.started?

        if entities_to_import.empty?
          bulk_import.finish!
        else
          entities_to_import.each do |entity|
            BulkImports::Importers::GroupImporter.new(entity).execute
          end

          # A new BulkImportWorker job is enqueued to either
          #   - Process the new BulkImports::Entity created for the subgroups
          #   - Or to mark the `bulk_import` as finished.
          BulkImportWorker.perform_async(bulk_import.id)
        end
      end

      private

      attr_reader :bulk_import

      def entities_to_import
        @entities_to_import ||= bulk_import.entities.with_status(:created)
      end
    end
  end
end
