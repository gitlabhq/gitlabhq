# frozen_string_literal: true

module BulkImports
  class NetworkError < Error
    TRACKER_COUNTER_KEY = 'bulk_imports/%{entity_id}/%{stage}/%{tracker_id}/network_error/%{error}'
    ENTITY_COUNTER_KEY = 'bulk_imports/%{entity_id}/network_error/%{error}'

    RETRIABLE_EXCEPTIONS = Gitlab::HTTP::HTTP_TIMEOUT_ERRORS + [
      EOFError, SocketError, OpenSSL::SSL::SSLError, OpenSSL::OpenSSLError,
      Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH
    ].freeze
    RETRIABLE_HTTP_CODES = [429].freeze

    DEFAULT_RETRY_DELAY_SECONDS = 30

    MAX_RETRIABLE_COUNT = 10

    attr_reader :response

    def initialize(message = nil, response: nil)
      raise ArgumentError, 'message or response required' if message.blank? && response.blank?

      super(message)

      @response = response
    end

    def retriable?(object)
      if retriable_exception? || retriable_http_code?
        increment(object) <= MAX_RETRIABLE_COUNT
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

    def retriable_exception?
      RETRIABLE_EXCEPTIONS.include?(cause&.class)
    end

    def retriable_http_code?
      RETRIABLE_HTTP_CODES.include?(response&.code)
    end

    def increment(object)
      key = object.is_a?(BulkImports::Entity) ? entity_cache_key(object) : tracker_cache_key(object)

      Gitlab::Cache::Import::Caching.increment(key)
    end

    def tracker_cache_key(tracker)
      TRACKER_COUNTER_KEY % {
        stage: tracker.stage,
        tracker_id: tracker.id,
        entity_id: tracker.entity.id,
        error: cause.class.name
      }
    end

    def entity_cache_key(entity)
      ENTITY_COUNTER_KEY % {
        import_id: entity.bulk_import_id,
        entity_id: entity.id,
        error: cause.class.name
      }
    end
  end
end
