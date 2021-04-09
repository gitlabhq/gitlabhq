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

      # For estimated distinct count use exact query instead of hll
      # buckets query, because it can't be used to obtain estimations without
      # supplementary ruby code present in Gitlab::Database::PostgresHll::BatchDistinctCounter
      def estimate_batch_distinct_count(relation, column = nil, *args, **kwargs)
        raw_sql(relation, column, :distinct)
      end

      def add(*args)
        'SELECT ' + args.map {|arg| "(#{arg})" }.join(' + ')
      end

      def maximum_id(model)
      end

      def minimum_id(model)
      end

      private

      def raw_sql(relation, column, distinct = nil)
        column ||= relation.primary_key
        relation.select(relation.all.table[column].count(distinct)).to_sql
      end
    end
  end
end
