# frozen_string_literal: true

module BulkImports
  class ExportStatus
    include Gitlab::Utils::StrongMemoize

    CACHE_KEY = 'bulk_imports/export_status/%{entity_id}/%{relation}'

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

    def total_objects_count
      return 0 if empty?

      status['total_objects_count']
    end

    private

    attr_reader :client, :entity, :relation, :pipeline_tracker

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

    def status_from_cache
      status = Gitlab::Cache::Import::Caching.read(cache_key)

      Gitlab::Json.parse(status) if status
    end

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

    def cache_status(status)
      Gitlab::Cache::Import::Caching.write(cache_key, status.to_json)
    end

    def cache_key
      Kernel.format(CACHE_KEY, entity_id: entity.id, relation: relation)
    end

    def status_endpoint
      File.join(entity.export_relations_url_path_base, 'status')
    end

    def default_error_response(message)
      { 'status' => Export::FAILED, 'error' => message }
    end
  end
end
