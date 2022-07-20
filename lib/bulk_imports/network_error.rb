# frozen_string_literal: true

module BulkImports
  class NetworkError < Error
    COUNTER_KEY = 'bulk_imports/%{entity_id}/%{stage}/%{tracker_id}/network_error/%{error}'

    RETRIABLE_EXCEPTIONS = Gitlab::HTTP::HTTP_TIMEOUT_ERRORS
    RETRIABLE_HTTP_CODES = [429].freeze

    DEFAULT_RETRY_DELAY_SECONDS = 30

    MAX_RETRIABLE_COUNT = 10

    def initialize(message = nil, response: nil)
      raise ArgumentError, 'message or response required' if message.blank? && response.blank?

      super(message)

      @response = response
    end

    def retriable?(tracker)
      if retriable_exception? || retriable_http_code?
        increment(tracker) <= MAX_RETRIABLE_COUNT
      else
        false
      end
    end

    def retry_delay
      if response&.code == 429
        response.headers.fetch('Retry-After', DEFAULT_RETRY_DELAY_SECONDS).to_i
      else
        DEFAULT_RETRY_DELAY_SECONDS
      end.seconds
    end

    private

    attr_reader :response

    def retriable_exception?
      RETRIABLE_EXCEPTIONS.include?(cause&.class)
    end

    def retriable_http_code?
      RETRIABLE_HTTP_CODES.include?(response&.code)
    end

    def increment(tracker)
      key = COUNTER_KEY % {
        stage: tracker.stage,
        tracker_id: tracker.id,
        entity_id: tracker.entity.id,
        error: cause.class.name
      }

      Gitlab::Cache::Import::Caching.increment(key)
    end
  end
end
