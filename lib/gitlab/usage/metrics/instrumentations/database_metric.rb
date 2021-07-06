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
          class << self
            def start(&block)
              return @metric_start&.call unless block_given?

              @metric_start = block
            end

            def finish(&block)
              return @metric_finish&.call unless block_given?

              @metric_finish = block
            end

            def relation(&block)
              return @metric_relation&.call unless block_given?

              @metric_relation = block
            end

            def operation(symbol, column: nil)
              @metric_operation = symbol
              @column = column
            end

            def cache_start_and_finish_as(cache_key)
              @cache_key = cache_key
            end

            attr_reader :metric_operation, :metric_relation, :metric_start, :metric_finish, :column, :cache_key
          end

          def value
            start, finish = get_or_cache_batch_ids

            method(self.class.metric_operation)
              .call(relation,
                    self.class.column,
                    start: start,
                    finish: finish)
          end

          def to_sql
            Gitlab::Usage::Metrics::Query.for(self.class.metric_operation, relation, self.class.column)
          end

          def suggested_name
            Gitlab::Usage::Metrics::NameSuggestion.for(
              self.class.metric_operation,
              relation: relation,
              column: self.class.column
            )
          end

          private

          def relation
            self.class.metric_relation.call.where(time_constraints)
          end

          def time_constraints
            case time_frame
            when '28d'
              monthly_time_range_db_params
            when 'all'
              {}
            when 'none'
              nil
            else
              raise "Unknown time frame: #{time_frame} for DatabaseMetric"
            end
          end

          def get_or_cache_batch_ids
            return [self.class.start, self.class.finish] unless self.class.cache_key.present?

            key_name = "metric_instrumentation/#{self.class.cache_key}"

            start = Gitlab::Cache.fetch_once("#{key_name}_minimum_id", expires_in: 1.day) do
              self.class.start
            end

            finish = Gitlab::Cache.fetch_once("#{key_name}_maximum_id", expires_in: 1.day) do
              self.class.finish
            end

            [start, finish]
          end
        end
      end
    end
  end
end
