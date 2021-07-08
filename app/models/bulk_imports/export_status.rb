# frozen_string_literal: true

module BulkImports
  class ExportStatus
    include Gitlab::Utils::StrongMemoize

    def initialize(pipeline_tracker, relation)
      @pipeline_tracker = pipeline_tracker
      @relation = relation
      @entity = @pipeline_tracker.entity
      @configuration = @entity.bulk_import.configuration
      @client = Clients::HTTP.new(url: @configuration.url, token: @configuration.access_token)
    end

    def started?
      export_status['status'] == Export::STARTED
    end

    def failed?
      export_status['status'] == Export::FAILED
    end

    def error
      export_status['error']
    end

    private

    attr_reader :client, :entity, :relation

    def export_status
      strong_memoize(:export_status) do
        fetch_export_status.find { |item| item['relation'] == relation }
      end
    rescue StandardError => e
      { 'status' => Export::FAILED, 'error' => e.message }
    end

    def fetch_export_status
      client.get(status_endpoint).parsed_response
    end

    def status_endpoint
      "/groups/#{entity.encoded_source_full_path}/export_relations/status"
    end
  end
end
