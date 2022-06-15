# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      class Query
        class << self
          def for(operation, relation, column = nil, **extra)
            case operation
            when :count
              count(relation, column)
            when :distinct_count
              distinct_count(relation, column)
            when :sum
              sum(relation, column)
            when :average
              average(relation, column)
            when :estimate_batch_distinct_count
              estimate_batch_distinct_count(relation, column)
            when :histogram
              histogram(relation, column, **extra)
            else
              raise ArgumentError, "#{operation} operation not supported"
            end
          end

          private

          def count(relation, column = nil)
            raw_count_sql(relation, column)
          end

          def distinct_count(relation, column = nil)
            raw_count_sql(relation, column, true)
          end

          def sum(relation, column)
            raw_sum_sql(relation, column)
          end

          def average(relation, column)
            raw_average_sql(relation, column)
          end

          def estimate_batch_distinct_count(relation, column = nil)
            raw_count_sql(relation, column, true)
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def histogram(relation, column, buckets:, bucket_size: buckets.size)
            count_grouped = relation.group(column).select(Arel.star.count.as('count_grouped'))
            cte = Gitlab::SQL::CTE.new(:count_cte, count_grouped)

            bucket_segments = bucket_size - 1
            width_bucket = Arel::Nodes::NamedFunction
              .new('WIDTH_BUCKET', [cte.table[:count_grouped], buckets.first, buckets.last, bucket_segments])
              .as('buckets')

            query = cte
              .table
              .project(width_bucket, cte.table[:count])
              .group('buckets')
              .order('buckets')
              .with(cte.to_arel)

            query.to_sql
          end
          # rubocop: enable CodeReuse/ActiveRecord

          # rubocop: disable CodeReuse/ActiveRecord
          def raw_count_sql(relation, column, distinct = false)
            column ||= relation.primary_key
            node = node_to_operate(relation, column)

            relation.unscope(:order).select(node.count(distinct)).to_sql
          end
          # rubocop: enable CodeReuse/ActiveRecord

          # rubocop: disable CodeReuse/ActiveRecord
          def raw_sum_sql(relation, column)
            node = node_to_operate(relation, column)

            relation.unscope(:order).select(node.sum).to_sql
          end
          # rubocop: enable CodeReuse/ActiveRecord

          # rubocop: disable CodeReuse/ActiveRecord
          def raw_average_sql(relation, column)
            node = node_to_operate(relation, column)

            relation.unscope(:order).select(node.average).to_sql
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def node_to_operate(relation, column)
            if join_relation?(relation) && joined_column?(column)
              table_name, column_name = column.split(".")
              Arel::Table.new(table_name)[column_name]
            else
              relation.all.table[column]
            end
          end

          def join_relation?(relation)
            relation.is_a?(ActiveRecord::Relation) && relation.joins_values.present?
          end

          # checks if the passed column is of format "table.column"
          def joined_column?(column)
            column.is_a?(String) && column.include?(".")
          end
        end
      end
    end
  end
end
