# frozen_string_literal: true

module BulkImports
  class ExportService
    def initialize(exportable:, user:)
      @exportable = exportable
      @current_user = user
    end

    def execute
      Export.config(exportable).exportable_relations.each do |relation|
        RelationExportWorker.perform_async(current_user.id, exportable.id, exportable.class.name, relation)
      end

      ServiceResponse.success
    rescue StandardError => e
      ServiceResponse.error(
        message: e.class,
        http_status: :unprocessable_entity
      )
    end

    private

    attr_reader :exportable, :current_user
  end
end
