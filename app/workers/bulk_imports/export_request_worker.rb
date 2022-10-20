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

      entity.update!(source_xid: entity_source_xid(entity)) if entity.source_xid.nil?

      request_export(entity)

      BulkImports::EntityWorker.perform_async(entity_id)
    rescue BulkImports::NetworkError => e
      if e.retriable?(entity)
        retry_request(e, entity)
      else
        log_exception(e,
          {
            bulk_import_entity_id: entity.id,
            bulk_import_id: entity.bulk_import_id,
            bulk_import_entity_type: entity.source_type,
            source_full_path: entity.source_full_path,
            message: "Request to export #{entity.source_type} failed",
            source_version: entity.bulk_import.source_version_info.to_s,
            importer: 'gitlab_migration'
          }
        )

        BulkImports::Failure.create(failure_attributes(e, entity))

        entity.fail_op!
      end
    end

    private

    def request_export(entity)
      http_client(entity).post(entity.export_relations_url_path)
    end

    def http_client(entity)
      @client ||= Clients::HTTP.new(
        url: entity.bulk_import.configuration.url,
        token: entity.bulk_import.configuration.access_token
      )
    end

    def failure_attributes(exception, entity)
      {
        bulk_import_entity_id: entity.id,
        pipeline_class: 'ExportRequestWorker',
        exception_class: exception.class.to_s,
        exception_message: exception.message.truncate(255),
        correlation_id_value: Labkit::Correlation::CorrelationId.current_or_new_id
      }
    end

    def graphql_client(entity)
      @graphql_client ||= BulkImports::Clients::Graphql.new(
        url: entity.bulk_import.configuration.url,
        token: entity.bulk_import.configuration.access_token
      )
    end

    def entity_source_xid(entity)
      query = entity_query(entity)
      client = graphql_client(entity)

      response = client.execute(
        client.parse(query.to_s),
        { full_path: entity.source_full_path }
      ).original_hash

      ::GlobalID.parse(response.dig(*query.data_path, 'id')).model_id
    rescue StandardError => e
      log_exception(e,
        {
          message: 'Failed to fetch source entity id',
          bulk_import_entity_id: entity.id,
          bulk_import_id: entity.bulk_import_id,
          bulk_import_entity_type: entity.source_type,
          source_full_path: entity.source_full_path,
          source_version: entity.bulk_import.source_version_info.to_s,
          importer: 'gitlab_migration'
        }
      )

      nil
    end

    def entity_query(entity)
      if entity.group?
        BulkImports::Groups::Graphql::GetGroupQuery.new(context: nil)
      else
        BulkImports::Projects::Graphql::GetProjectQuery.new(context: nil)
      end
    end

    def retry_request(exception, entity)
      log_exception(exception,
        {
          message: 'Retrying export request',
          bulk_import_entity_id: entity.id,
          bulk_import_id: entity.bulk_import_id,
          bulk_import_entity_type: entity.source_type,
          source_full_path: entity.source_full_path,
          source_version: entity.bulk_import.source_version_info.to_s,
          importer: 'gitlab_migration'
        }
      )

      self.class.perform_in(2.seconds, entity.id)
    end

    def logger
      @logger ||= Gitlab::Import::Logger.build
    end

    def log_exception(exception, payload)
      Gitlab::ExceptionLogFormatter.format!(exception, payload)

      logger.error(structured_payload(payload))
    end
  end
end
