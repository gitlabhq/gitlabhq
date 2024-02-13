# frozen_string_literal: true

module ClickHouse
  class RecordSyncContext
    attr_reader :last_record_id, :last_processed_id, :total_record_count, :record_count_in_current_batch

    def initialize(
      last_record_id:, max_records_per_batch:,
      runtime_limiter: Gitlab::Metrics::RuntimeLimiter.new)
      @last_record_id = last_record_id
      @runtime_limiter = runtime_limiter
      @max_records_per_batch = max_records_per_batch
      @last_processed_id = nil
      @record_count_in_current_batch = 0
      @total_record_count = 0
    end

    delegate :over_time?, to: :@runtime_limiter

    def new_batch!
      @record_count_in_current_batch = 0
    end

    def no_more_records!
      @no_more_records = true
    end

    def no_more_records?
      !!@no_more_records
    end

    def last_processed_id=(value)
      @record_count_in_current_batch += 1
      @total_record_count += 1
      @last_processed_id = value
      @last_record_id = value
    end

    def record_limit_reached?
      @record_count_in_current_batch == @max_records_per_batch
    end
  end
end
