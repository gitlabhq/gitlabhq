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
        query = build_query(&block)

        ActiveRecord::Base.connection.exec_query(query.to_sql)
      end

      private

      def build_query
        base_query = base_query_for(@stage)
        diff_fn = subtract_datetimes_diff(base_query, stage_class.start_time_attrs, stage_class.end_time_attrs)

        yield(stage_class, base_query) if block_given?

        base_query.project(extract_epoch(diff_fn).as('total_time'), *stage_class.projections).order(stage_class.order.desc)
      end

      def extract_epoch(arel_attribute)
        return arel_attribute unless Gitlab::Database.postgresql?

        Arel.sql(%Q{EXTRACT(EPOCH FROM (#{arel_attribute.to_sql}))})
      end

      def stage_class
        @stage_class ||= "Gitlab::CycleAnalytics::#{@stage.to_s.camelize}Config".constantize
      end
    end
  end
end
