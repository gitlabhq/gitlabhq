module Gitlab
  module CycleAnalytics
    class EventsQuery
      include MetricsFetcher

      def initialize(project:, from:)
        @project = project
        @from = from
      end

      def execute(stage, config, &block)
        @stage = stage
        @config = config
        query = build_query(&block)

        ActiveRecord::Base.connection.execute(query.to_sql).to_a
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
