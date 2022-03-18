# frozen_string_literal: true

module BulkImports
  class ExportRequestWorker
    include ApplicationWorker

    data_consistency :always

    idempotent!
    worker_has_external_dependencies!
    feature_category :importers

    def perform(entity_id)
      entity = BulkImports::Entity.find(entity_id)

      request_export(entity)
    rescue BulkImports::NetworkError => e
      log_export_failure(e, entity)

      entity.fail_op!
    end

    private

    def request_export(entity)
      http_client(entity.bulk_import.configuration).post(entity.export_relations_url_path)
    end

    def http_client(configuration)
      @client ||= Clients::HTTP.new(
        url: configuration.url,
        token: configuration.access_token
      )
    end

    def log_export_failure(exception, entity)
      attributes = {
        bulk_import_entity_id: entity.id,
        pipeline_class: 'ExportRequestWorker',
        exception_class: exception.class.to_s,
        exception_message: exception.message.truncate(255),
        correlation_id_value: Labkit::Correlation::CorrelationId.current_or_new_id
      }

      Gitlab::Import::Logger.warn(
        attributes.merge(
          bulk_import_id: entity.bulk_import.id,
          bulk_import_entity_type: entity.source_type
        )
      )

      BulkImports::Failure.create(attributes)
    end
  end
end
