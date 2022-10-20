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
      !empty? && export_status['status'] == Export::STARTED
    end

    def failed?
      !empty? && export_status['status'] == Export::FAILED
    end

    def empty?
      export_status.nil?
    end

    def error
      export_status['error']
    end

    private

    attr_reader :client, :entity, :relation, :pipeline_tracker

    def export_status
      strong_memoize(:export_status) do
        fetch_export_status&.find { |item| item['relation'] == relation }
      rescue BulkImports::NetworkError => e
        raise BulkImports::RetryPipelineError.new(e.message, 2.seconds) if e.retriable?(pipeline_tracker)

        default_error_response(e.message)
      rescue StandardError => e
        default_error_response(e.message)
      end
    end

    def fetch_export_status
      client.get(status_endpoint).parsed_response
    end

    def status_endpoint
      File.join(entity.export_relations_url_path, 'status')
    end

    def default_error_response(message)
      { 'status' => Export::FAILED, 'error' => message }
    end
  end
end
