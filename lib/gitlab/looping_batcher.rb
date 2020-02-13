# frozen_string_literal: true

module Gitlab
  # Returns an ID range within a table so it can be iterated over. Repeats from
  # the beginning after it reaches the end.
  #
  # Used by Geo in particular to iterate over a replicable and its registry
  # table.
  #
  # Tracks a cursor for each table, by "key". If the table is smaller than
  # batch_size, then a range for the whole table is returned on every call.
  class LoopingBatcher
    # @param [Class] model_class the class of the table to iterate on
    # @param [String] key to identify the cursor. Note, cursor is already unique
    #   per table.
    # @param [Integer] batch_size to limit the number of records in a batch
    def initialize(model_class, key:, batch_size: 1000)
      @model_class = model_class
      @key = key
      @batch_size = batch_size
    end

    # @return [Range] a range of IDs. `nil` if 0 records at or after the cursor.
    def next_range!
      return unless @model_class.any?

      batch_first_id = cursor_id

      batch_last_id = get_batch_last_id(batch_first_id)
      return unless batch_last_id

      batch_first_id..batch_last_id
    end

    private

    # @private
    #
    # Get the last ID of the batch. Increment the cursor or reset it if at end.
    #
    # @param [Integer] batch_first_id the first ID of the batch
    # @return [Integer] batch_last_id the last ID of the batch (not the table)
    def get_batch_last_id(batch_first_id)
      batch_last_id, more_rows = run_query(@model_class.table_name, @model_class.primary_key, batch_first_id, @batch_size)

      if more_rows
        increment_batch(batch_last_id)
      else
        reset if batch_first_id > 1
      end

      batch_last_id
    end

    def run_query(table, primary_key, batch_first_id, batch_size)
      sql = <<~SQL
        SELECT MAX(batch.id) AS batch_last_id,
        EXISTS (
          SELECT #{primary_key}
          FROM #{table}
          WHERE #{primary_key} > MAX(batch.id)
        ) AS more_rows
        FROM (
          SELECT #{primary_key}
          FROM #{table}
          WHERE #{primary_key} >= #{batch_first_id}
          ORDER BY #{primary_key}
          LIMIT #{batch_size}) AS batch;
      SQL

      result = ActiveRecord::Base.connection.exec_query(sql).first

      [result["batch_last_id"], result["more_rows"]]
    end

    def reset
      set_cursor_id(1)
    end

    def increment_batch(batch_last_id)
      set_cursor_id(batch_last_id + 1)
    end

    # @private
    #
    # @return [Integer] the cursor ID, or 1 if it is not set
    def cursor_id
      Rails.cache.fetch("#{cache_key}:cursor_id") || 1
    end

    def set_cursor_id(id)
      Rails.cache.write("#{cache_key}:cursor_id", id)
    end

    def cache_key
      @cache_key ||= "#{self.class.name.parameterize}:#{@model_class.name.parameterize}:#{@key}:cursor_id"
    end
  end
end
