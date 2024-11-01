# frozen_string_literal: true

module Gitlab
  module Database
    class ConsistencyChecker
      BATCH_SIZE = 500
      MAX_BATCHES = 20
      MAX_RUNTIME = 5.seconds # must be less than the scheduling frequency of the ConsistencyCheck jobs

      delegate :monotonic_time, to: :'Gitlab::Metrics::System'

      def initialize(source_model:, target_model:, source_columns:, target_columns:)
        @source_model = source_model
        @target_model = target_model
        @source_columns = source_columns
        @target_columns = target_columns
        @source_sort_column = source_columns.first
        @target_sort_column = target_columns.first
        @result = { matches: 0, mismatches: 0, batches: 0, mismatches_details: [] }
      end

      def execute(start_id:)
        current_start_id = start_id

        return build_result(next_start_id: nil) if max_id.nil?
        return build_result(next_start_id: min_id) if current_start_id > max_id

        @start_time = monotonic_time

        MAX_BATCHES.times do
          if (current_start_id <= max_id) && !over_time_limit?
            ids_range = current_start_id...(current_start_id + BATCH_SIZE)
            # rubocop: disable CodeReuse/ActiveRecord
            source_data = source_model.where(source_sort_column => ids_range)
                            .order(source_sort_column => :asc).pluck(*source_columns)
            target_data = target_model.where(target_sort_column => ids_range)
                            .order(target_sort_column => :asc).pluck(*target_columns)
            # rubocop: enable CodeReuse/ActiveRecord

            current_start_id += BATCH_SIZE
            result[:matches] += append_mismatches_details(source_data, target_data)
            result[:batches] += 1
          else
            break
          end
        end

        result[:mismatches] = result[:mismatches_details].length
        metrics_counter.increment({ source_table: source_model.table_name, result: "match" }, result[:matches])
        metrics_counter.increment({ source_table: source_model.table_name, result: "mismatch" }, result[:mismatches])

        build_result(next_start_id: current_start_id > max_id ? min_id : current_start_id)
      end

      private

      attr_reader :source_model, :target_model, :source_columns, :target_columns,
        :source_sort_column, :target_sort_column, :start_time, :result

      def build_result(next_start_id:)
        { next_start_id: next_start_id }.merge(result)
      end

      def over_time_limit?
        (monotonic_time - start_time) >= MAX_RUNTIME
      end

      # This where comparing the items happen, and building the diff log
      # It returns the number of matching elements
      def append_mismatches_details(source_data, target_data)
        # Mapping difference the sort key to the item values
        # source - target
        source_diff_hash = (source_data - target_data).index_by { |item| item.shift }
        # target - source
        target_diff_hash = (target_data - source_data).index_by { |item| item.shift }

        matches = source_data.length - source_diff_hash.length

        # Items that exist in the first table + Different items
        source_diff_hash.each do |id, values|
          result[:mismatches_details] << {
            id: id,
            source_table: values,
            target_table: target_diff_hash[id]
          }
        end

        # Only the items that exist in the target table
        target_diff_hash.each do |id, values|
          next if source_diff_hash[id] # It's already added

          result[:mismatches_details] << {
            id: id,
            source_table: source_diff_hash[id],
            target_table: values
          }
        end

        matches
      end

      def min_id
        @min_id ||= source_model.minimum(source_sort_column)
      end

      def max_id
        @max_id ||= source_model.maximum(source_sort_column)
      end

      def metrics_counter
        @metrics_counter ||= Gitlab::Metrics.counter(
          :consistency_checks,
          "Consistency Check Results"
        )
      end
    end
  end
end
