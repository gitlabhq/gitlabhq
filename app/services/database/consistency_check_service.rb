# frozen_string_literal: true

module Database
  class ConsistencyCheckService
    CURSOR_REDIS_KEY_TTL = 7.days
    EMPTY_RESULT = { matches: 0, mismatches: 0, batches: 0, mismatches_details: [] }.freeze

    def initialize(source_model:, target_model:, source_columns:, target_columns:)
      @source_model = source_model
      @target_model = target_model
      @source_columns = source_columns
      @target_columns = target_columns
      @source_sort_column = source_columns.first
      @target_sort_column = target_columns.first
    end

    # This class takes two ActiveRecord models, and compares the selected columns
    # of the two models tables, for the purposes of checking the consistency of
    # mirroring of tables. For example Namespace and Ci::NamepaceMirror
    #
    # It compares up to 25 batches (1000 records / batch), or up to 30 seconds
    # for all the batches in total.
    #
    # It saves the cursor of the next start_id (cursor) in Redis. If the start_id
    # wasn't saved in Redis, for example, in the first run, it will choose some random start_id
    #
    # Example:
    #    service = Database::ConsistencyCheckService.new(
    #      source_model: Namespace,
    #      target_model: Ci::NamespaceMirror,
    #      source_columns: %w[id traversal_ids],
    #      target_columns: %w[namespace_id traversal_ids],
    #    )
    #    result = service.execute
    #
    # result is a hash that has the following fields:
    # - batches: Number of batches checked
    # - matches: The number of matched records
    # - mismatches: The number of mismatched records
    # - mismatches_details: It's an array that contains details about the mismatched records.
    #     each record in this array is a hash of format {id: ID, source_table: [...], target_table: [...]}
    #     Each record represents the attributes of the records in the two tables.
    # - start_id: The start id cursor of the current batch. <nil> means no records.
    # - next_start_id: The ID that can be used for the next batch iteration check. <nil> means no records
    def execute
      start_id = next_start_id

      return EMPTY_RESULT if start_id.nil?

      result = consistency_checker.execute(start_id: start_id)
      result[:start_id] = start_id

      save_next_start_id(result[:next_start_id])

      result
    end

    private

    attr_reader :source_model, :target_model, :source_columns, :target_columns, :source_sort_column, :target_sort_column

    def consistency_checker
      @consistency_checker ||= Gitlab::Database::ConsistencyChecker.new(
        source_model: source_model,
        target_model: target_model,
        source_columns: source_columns,
        target_columns: target_columns
      )
    end

    def next_start_id
      return if min_id.nil?

      fetch_next_start_id || random_start_id
    end

    def min_id
      @min_id ||= source_model.minimum(source_sort_column)
    end

    def max_id
      @max_id ||= source_model.maximum(source_sort_column)
    end

    def fetch_next_start_id
      Gitlab::Redis::SharedState.with { |redis| redis.get(cursor_redis_shared_state_key)&.to_i }
    end

    # This returns some random start_id, so that we don't always start checking
    # from the start of the table, in case we lose the cursor in Redis.
    def random_start_id
      range_start = min_id
      range_end = [min_id, max_id - Gitlab::Database::ConsistencyChecker::BATCH_SIZE].max
      rand(range_start..range_end)
    end

    def save_next_start_id(start_id)
      Gitlab::Redis::SharedState.with do |redis|
        redis.set(cursor_redis_shared_state_key, start_id, ex: CURSOR_REDIS_KEY_TTL)
      end
    end

    def cursor_redis_shared_state_key
      "consistency_check_cursor:#{source_model.table_name}:#{target_model.table_name}"
    end
  end
end
