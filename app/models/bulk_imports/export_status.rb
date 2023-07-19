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
      !empty? && status['status'] == Export::STARTED
    end

    def failed?
      !empty? && status['status'] == Export::FAILED
    end

    def empty?
      status.nil?
    end

    def error
      status['error']
    end

    def batched?
      status['batched'] == true
    end

    def batches_count
      status['batches_count'].to_i
    end

    def batch(batch_number)
      raise ArgumentError if batch_number < 1

      return unless batched?

      status['batches'].find { |item| item['batch_number'] == batch_number }
    end

    private

    attr_reader :client, :entity, :relation, :pipeline_tracker

    def status
      strong_memoize(:status) do
        status = fetch_status

        next status if status.is_a?(Hash) || status.nil?

        status.find { |item| item['relation'] == relation }
      rescue BulkImports::NetworkError => e
        raise BulkImports::RetryPipelineError.new(e.message, 2.seconds) if e.retriable?(pipeline_tracker)

        default_error_response(e.message)
      rescue StandardError => e
        default_error_response(e.message)
      end
    end

    def fetch_status
      client.get(status_endpoint, relation: relation).parsed_response
    end

    def status_endpoint
      File.join(entity.export_relations_url_path_base, 'status')
    end

    def default_error_response(message)
      { 'status' => Export::FAILED, 'error' => message }
    end
  end
end
