# frozen_string_literal: true

# For large tables, PostgreSQL can take a long time to count rows due to MVCC.
# Implements a distinct and ordinary batch counter
# Needs indexes on the column below to calculate max, min and range queries
# For larger tables just set use higher batch_size with index optimization
#
# In order to not use a possible complex time consuming query when calculating min and max for batch_distinct_count
# the start and finish can be sent specifically
#
# Grouped relations can be used as well. However, the preferred batch count should be around 10K because group by count is more expensive.
#
# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22705
#
# Examples:
#  extend ::Gitlab::Database::BatchCount
#  batch_count(User.active)
#  batch_count(::Clusters::Cluster.aws_installed.enabled, :cluster_id)
#  batch_count(Namespace.group(:type))
#  batch_distinct_count(::Project, :creator_id)
#  batch_distinct_count(::Project.aimed_for_deletion.service_desk_enabled.where(time_period), start: ::User.minimum(:id), finish: ::User.maximum(:id))
#  batch_distinct_count(Project.group(:visibility_level), :creator_id)
#  batch_sum(User, :sign_in_count)
#  batch_sum(Issue.group(:state_id), :weight))
module Gitlab
  module Database
    module BatchCount
      def batch_count(relation, column = nil, batch_size: nil, start: nil, finish: nil)
        BatchCounter.new(relation, column: column).count(batch_size: batch_size, start: start, finish: finish)
      end

      def batch_distinct_count(relation, column = nil, batch_size: nil, start: nil, finish: nil)
        BatchCounter.new(relation, column: column).count(mode: :distinct, batch_size: batch_size, start: start, finish: finish)
      end

      def batch_sum(relation, column, batch_size: nil, start: nil, finish: nil)
        BatchCounter.new(relation, column: nil, operation: :sum, operation_args: [column]).count(batch_size: batch_size, start: start, finish: finish)
      end

      class << self
        include BatchCount
      end
    end

    class BatchCounter
      FALLBACK = -1
      MIN_REQUIRED_BATCH_SIZE = 1_250
      DEFAULT_SUM_BATCH_SIZE = 1_000
      MAX_ALLOWED_LOOPS = 10_000
      SLEEP_TIME_IN_SECONDS = 0.01 # 10 msec sleep
      ALLOWED_MODES = [:itself, :distinct].freeze
      FALLBACK_FINISH = 0
      OFFSET_BY_ONE = 1

      # Each query should take < 500ms https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22705
      DEFAULT_DISTINCT_BATCH_SIZE = 10_000
      DEFAULT_BATCH_SIZE = 100_000

      def initialize(relation, column: nil, operation: :count, operation_args: nil)
        @relation = relation
        @column = column || relation.primary_key
        @operation = operation
        @operation_args = operation_args
      end

      def unwanted_configuration?(finish, batch_size, start)
        (@operation == :count && batch_size <= MIN_REQUIRED_BATCH_SIZE) ||
          (@operation == :sum && batch_size < DEFAULT_SUM_BATCH_SIZE) ||
          (finish - start) / batch_size >= MAX_ALLOWED_LOOPS ||
          start >= finish
      end

      def count(batch_size: nil, mode: :itself, start: nil, finish: nil)
        raise 'BatchCount can not be run inside a transaction' if ActiveRecord::Base.connection.transaction_open?

        check_mode!(mode)

        # non-distinct have better performance
        batch_size ||= batch_size_for_mode_and_operation(mode, @operation)

        start = actual_start(start)
        finish = actual_finish(finish)

        raise "Batch counting expects positive values only for #{@column}" if start < 0 || finish < 0
        return FALLBACK if unwanted_configuration?(finish, batch_size, start)

        results = nil
        batch_start = start

        while batch_start < finish
          begin
            batch_end = [batch_start + batch_size, finish].min
            batch_relation = build_relation_batch(batch_start, batch_end, mode)

            op_args = @operation_args
            if @operation == :count && @operation_args.blank? && use_loose_index_scan_for_distinct_values?(mode)
              op_args = [Gitlab::Database::LooseIndexScanDistinctCount::COLUMN_ALIAS]
            end

            results = merge_results(results, batch_relation.send(@operation, *op_args)) # rubocop:disable GitlabSecurity/PublicSend
            batch_start = batch_end
          rescue ActiveRecord::QueryCanceled => error
            # retry with a safe batch size & warmer cache
            if batch_size >= 2 * MIN_REQUIRED_BATCH_SIZE
              batch_size /= 2
            else
              log_canceled_batch_fetch(batch_start, mode, batch_relation.to_sql, error)
              return FALLBACK
            end
          rescue Gitlab::Database::LooseIndexScanDistinctCount::ColumnConfigurationError => error
            Gitlab::AppJsonLogger
              .error(
                event: 'batch_count',
                relation: @relation.table_name,
                operation: @operation,
                operation_args: @operation_args,
                mode: mode,
                message: "LooseIndexScanDistinctCount column error: #{error.message}"
              )

            return FALLBACK
          end

          sleep(SLEEP_TIME_IN_SECONDS)
        end

        results
      end

      def merge_results(results, object)
        return object unless results

        if object.is_a?(Hash)
          results.merge!(object) { |_, a, b| a + b }
        else
          results + object
        end
      end

      private

      def build_relation_batch(start, finish, mode)
        if use_loose_index_scan_for_distinct_values?(mode)
          Gitlab::Database::LooseIndexScanDistinctCount.new(@relation, @column).build_query(from: start, to: finish)
        else
          @relation.select(@column).public_send(mode).where(between_condition(start, finish)) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      def batch_size_for_mode_and_operation(mode, operation)
        return DEFAULT_SUM_BATCH_SIZE if operation == :sum

        mode == :distinct ? DEFAULT_DISTINCT_BATCH_SIZE : DEFAULT_BATCH_SIZE
      end

      def between_condition(start, finish)
        return @column.between(start...finish) if @column.is_a?(Arel::Attributes::Attribute)

        { @column => start...finish }
      end

      def actual_start(start)
        start || @relation.unscope(:group, :having).minimum(@column) || 0
      end

      def actual_finish(finish)
        (finish || @relation.unscope(:group, :having).maximum(@column) || FALLBACK_FINISH) + OFFSET_BY_ONE
      end

      def check_mode!(mode)
        raise "The mode #{mode.inspect} is not supported" unless ALLOWED_MODES.include?(mode)
        raise 'Use distinct count for optimized distinct counting' if @relation.limit(1).distinct_value.present? && mode != :distinct
        raise 'Use distinct count only with non id fields' if @column == :id && mode == :distinct
      end

      def log_canceled_batch_fetch(batch_start, mode, query, error)
        Gitlab::AppJsonLogger
          .error(
            event: 'batch_count',
            relation: @relation.table_name,
            operation: @operation,
            operation_args: @operation_args,
            start: batch_start,
            mode: mode,
            query: query,
            message: "Query has been canceled with message: #{error.message}"
          )
      end

      def use_loose_index_scan_for_distinct_values?(mode)
        Feature.enabled?(:loose_index_scan_for_distinct_values) && not_group_by_query? && mode == :distinct
      end

      def not_group_by_query?
        !@relation.is_a?(ActiveRecord::Relation) || @relation.group_values.blank?
      end
    end
  end
end
