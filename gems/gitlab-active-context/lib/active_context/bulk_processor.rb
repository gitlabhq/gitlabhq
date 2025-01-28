# frozen_string_literal: true

module ActiveContext
  class BulkProcessor
    attr_reader :failures, :adapter

    def initialize
      @failures = []
      @adapter = ActiveContext.adapter
    end

    def process(ref)
      send_bulk if @adapter.add_ref(ref)
    end

    def flush
      send_bulk.failures
    end

    private

    def send_bulk
      return self if adapter.empty?

      failed_refs = try_send_bulk

      logger.info(
        'message' => 'bulk_submitted',
        'meta.indexing.bulk_count' => adapter.all_refs.size,
        'meta.indexing.errors_count' => failed_refs.count
      )

      failures.push(*failed_refs)

      adapter.reset

      self
    end

    def try_send_bulk
      result = adapter.bulk
      adapter.process_bulk_errors(result)
    rescue StandardError => e
      logger.error(message: 'bulk_exception', error_class: e.class.to_s, error_message: e.message)
      adapter.all_refs
    end

    def logger
      @logger ||= ActiveContext::Config.logger
    end
  end
end
