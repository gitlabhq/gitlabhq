module Gitlab
  module CycleAnalytics
    class EventsQuery
      include MetricsFetcher

      def initialize(project:, options: {})
        @project = project
        @from = options[:from]
        @branch = options[:branch]
      end

      def execute(stage, &block)
        @stage = stage
        @config = QueryConfig.get(stage)
        query = build_query(&block)

        ActiveRecord::Base.connection.exec_query(query.to_sql)
      end

      private

      def build_query
        base_query = base_query_for(@stage)
        diff_fn = subtract_datetimes_diff(@config[:base_query], @config[:start_time_attrs], @config[:end_time_attrs])

        yield base_query if block_given?

        base_query.project(extract_epoch(diff_fn).as('total_time'), *@config[:projections]).order(order.desc)
      end

      def order
        @config[:order] || @config[:start_time_attrs]
      end

      def extract_epoch(arel_attribute)
        return arel_attribute unless Gitlab::Database.postgresql?

        Arel.sql(%Q{EXTRACT(EPOCH FROM (#{arel_attribute.to_sql}))})
      end
    end
  end
end
