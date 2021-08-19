# frozen_string_literal: true

module BulkImports
  class ExportRequestWorker
    include ApplicationWorker

    data_consistency :always

    idempotent!
    worker_has_external_dependencies!
    feature_category :importers

    GROUP_EXPORTED_URL_PATH = "/groups/%s/export_relations"

    def perform(entity_id)
      entity = BulkImports::Entity.find(entity_id)

      request_export(entity)
    end

    private

    def request_export(entity)
      http_client(entity.bulk_import.configuration)
        .post(GROUP_EXPORTED_URL_PATH % entity.encoded_source_full_path)
    end

    def http_client(configuration)
      @client ||= Clients::HTTP.new(
        url: configuration.url,
        token: configuration.access_token
      )
    end
  end
end
