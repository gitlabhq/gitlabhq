# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class DatabaseMetric < BaseMetric
          # Usage Example
          #
          # class CountUsersCreatingIssuesMetric < DatabaseMetric
          #   operation :distinct_count, column: :author_id
          #
          #   relation do |database_time_constraints|
          #     ::Issue.where(database_time_constraints)
          #   end
          # end

          UnimplementedOperationError = Class.new(StandardError)

          class << self
            IMPLEMENTED_OPERATIONS = %i[count distinct_count estimate_batch_distinct_count sum average].freeze

            private_constant :IMPLEMENTED_OPERATIONS

            def start(&block)
              return @metric_start&.call unless block

              @metric_start = block
            end

            def finish(&block)
              return @metric_finish&.call unless block

              @metric_finish = block
            end

            def relation(relation_proc = nil, &block)
              return unless relation_proc || block

              @metric_relation = (relation_proc || block)
            end

            def metric_options(&block)
              return @metric_options&.call.to_h unless block

              @metric_options = block
            end

            def timestamp_column(symbol)
              @metric_timestamp_column = symbol
            end

            def operation(symbol, column: nil, &block)
              raise UnimplementedOperationError unless symbol.in?(IMPLEMENTED_OPERATIONS)

              @metric_operation = symbol
              @column = column
              @metric_operation_block = block if block
            end

            def cache_start_and_finish_as(cache_key)
              @cache_key = cache_key
            end

            attr_reader :metric_operation, :metric_relation, :metric_start,
              :metric_finish, :metric_operation_block,
              :column, :cache_key, :metric_timestamp_column
          end

          def value
            start, finish = get_or_cache_batch_ids

            method(self.class.metric_operation)
              .call(relation,
                self.class.column,
                start: start,
                finish: finish,
                **self.class.metric_options,
                &self.class.metric_operation_block)
          end

          def to_sql
            Gitlab::Usage::Metrics::Query.for(self.class.metric_operation, relation, self.class.column)
          end

          def instrumentation
            to_sql
          end

          private

          def start
            self.class.metric_start&.call(time_constraints)
          end

          def finish
            self.class.metric_finish&.call(time_constraints)
          end

          def relation
            if self.class.metric_relation.arity == 1
              self.class.metric_relation.call(options)
            else
              self.class.metric_relation.call
            end.where(time_constraints)
          end

          def time_constraints
            case time_frame
            when '28d'
              monthly_time_range_db_params(column: self.class.metric_timestamp_column)
            when '7d'
              weekly_time_range_db_params(column: self.class.metric_timestamp_column)
            when 'all'
              {}
            when 'none'
              nil
            else
              raise "Unknown time frame: #{time_frame} for DatabaseMetric"
            end
          end

          def get_or_cache_batch_ids
            return [start, finish] unless self.class.cache_key.present?

            key_name = "metric_instrumentation/#{self.class.cache_key}"

            cached_start = Gitlab::Cache.fetch_once("#{key_name}_minimum_id", expires_in: 1.day) do
              start
            end

            cached_finish = Gitlab::Cache.fetch_once("#{key_name}_maximum_id", expires_in: 1.day) do
              finish
            end

            [cached_start, cached_finish]
          end
        end
      end
    end
  end
end
