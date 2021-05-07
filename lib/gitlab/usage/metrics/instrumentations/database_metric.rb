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
              @metric_start = block
            end

            def finish(&block)
              @metric_finish = block
            end

            def relation(&block)
              @metric_relation = block
            end

            def operation(symbol, column: nil)
              @metric_operation = symbol
              @column = column
            end

            attr_reader :metric_operation, :metric_relation, :metric_start, :metric_finish, :column
          end

          def value
            method(self.class.metric_operation)
              .call(relation,
                    self.class.column,
                    start: self.class.metric_start&.call,
                    finish: self.class.metric_finish&.call)
          end

          def relation
            self.class.metric_relation.call.where(time_constraints)
          end

          private

          def time_constraints
            case time_frame
            when '28d'
              { created_at: 30.days.ago..2.days.ago }
            when 'all'
              {}
            when 'none'
              nil
            else
              raise "Unknown time frame: #{time_frame} for DatabaseMetric"
            end
          end
        end
      end
    end
  end
end
