# frozen_string_literal: true

module BulkImports
  class ExportStatus < ::Import::ExportStatus
    def initialize(pipeline_tracker, relation)
      super

      @configuration = @entity.bulk_import.configuration
      @client = Clients::HTTP.new(url: @configuration.url, token: @configuration.access_token)
    end

    def in_progress?
      !waiting_on_export? && Export::IN_PROGRESS_STATUSES.include?(status['status'])
    end

    def failed?
      !waiting_on_export? && status['status'] == Export::FAILED
    end

    def waiting_on_export?
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

    def all_batch_numbers
      (1..batches_count).to_a
    end

    def batch_failed?(batch_number)
      batch(batch_number)&.dig('status') == BulkImports::ExportBatch::STATE_VALUES[:failed]
    end

    def batch_error(batch_number)
      batch(batch_number)&.dig('error')
    end

    def total_objects_count
      return 0 if waiting_on_export?

      status['total_objects_count']
    end

    private

    attr_reader :client

    def status
      # As an optimization, once an export status has finished or failed it will
      # be cached, so we do not fetch from the remote source again.
      cached_status = status_from_cache
      return cached_status if cached_status

      status_from_remote
    rescue BulkImports::NetworkError => e
      raise BulkImports::RetryPipelineError.new(e.message, 2.seconds) if e.retriable?(pipeline_tracker)

      default_error_response(e.message)
    rescue StandardError => e
      default_error_response(e.message)
    end
    strong_memoize_attr :status

    def status_from_remote
      raw_status = client.get(status_endpoint, relation: relation).parsed_response

      parse_status_from_remote(raw_status).tap do |status|
        cache_status(status) if cache_status?(status)
      end
    end

    def parse_status_from_remote(status)
      # Non-batched status
      return status if status.is_a?(Hash) || status.nil?

      # Batched status
      status.find { |item| item['relation'] == relation }
    end

    def cache_status?(status)
      status.present? && status['status'].in?([Export::FINISHED, Export::FAILED])
    end

    def status_endpoint
      File.join(entity.export_relations_url_path_base, 'status')
    end

    def batch(batch_number)
      raise ArgumentError, "Batch number (#{batch_number}) must be >= 1" if batch_number < 1

      return unless batched?

      status['batches'].find { |item| item['batch_number'] == batch_number }
    end

    def default_error_response(message)
      { 'status' => Export::FAILED, 'error' => message }
    end
  end
end
