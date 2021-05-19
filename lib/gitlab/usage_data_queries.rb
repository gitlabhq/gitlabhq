# frozen_string_literal: true

module Gitlab
  # This class is used by the `gitlab:usage_data:dump_sql` rake tasks to output SQL instead of running it.
  # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/41091
  class UsageDataQueries < UsageData
    class << self
      def count(relation, column = nil, *args, **kwargs)
        raw_sql(relation, column)
      end

      def distinct_count(relation, column = nil, *args, **kwargs)
        raw_sql(relation, column, :distinct)
      end

      def redis_usage_data(counter = nil, &block)
        if block_given?
          { redis_usage_data_block: block.to_s }
        elsif counter.present?
          { redis_usage_data_counter: counter }
        end
      end

      def sum(relation, column, *args, **kwargs)
        relation.select(relation.all.table[column].sum).to_sql
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

      # For estimated distinct count use exact query instead of hll
      # buckets query, because it can't be used to obtain estimations without
      # supplementary ruby code present in Gitlab::Database::PostgresHll::BatchDistinctCounter
      def estimate_batch_distinct_count(relation, column = nil, *args, **kwargs)
        raw_sql(relation, column, :distinct)
      end

      def add(*args)
        'SELECT ' + args.map {|arg| "(#{arg})" }.join(' + ')
      end

      def maximum_id(model, column = nil)
      end

      def minimum_id(model, column = nil)
      end

      def jira_service_data
        {
          projects_jira_server_active: 0,
          projects_jira_cloud_active: 0
        }
      end

      def epics_deepest_relationship_level
        { epics_deepest_relationship_level: 0 }
      end

      private

      def raw_sql(relation, column, distinct = nil)
        column ||= relation.primary_key
        relation.select(relation.all.table[column].count(distinct)).to_sql
      end
    end
  end
end
