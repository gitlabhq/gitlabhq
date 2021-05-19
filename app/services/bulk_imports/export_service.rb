# frozen_string_literal: true

module BulkImports
  class ExportService
    def initialize(portable:, user:)
      @portable = portable
      @current_user = user
    end

    def execute
      FileTransfer.config_for(portable).portable_relations.each do |relation|
        RelationExportWorker.perform_async(current_user.id, portable.id, portable.class.name, relation)
      end

      ServiceResponse.success
    rescue StandardError => e
      ServiceResponse.error(
        message: e.class,
        http_status: :unprocessable_entity
      )
    end

    private

    attr_reader :portable, :current_user
  end
end
