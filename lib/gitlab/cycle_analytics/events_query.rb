module Gitlab
  module CycleAnalytics
    class EventsQuery
      attr_reader :project

      def initialize(project:, options: {})
        @project = project
        @from = options[:from]
        @branch = options[:branch]
        @fetcher = Gitlab::CycleAnalytics::MetricsFetcher.new(project: project, from: @from, branch: @branch)
      end

      def execute(stage_class)
        @stage_class = stage_class

        ActiveRecord::Base.connection.exec_query(query.to_sql)
      end

      private

      def query
        base_query = @fetcher.base_query_for(@stage_class.stage)
        diff_fn = @fetcher.subtract_datetimes_diff(base_query, @stage_class.start_time_attrs, @stage_class.end_time_attrs)

        @stage_class.custom_query(base_query)

        base_query.project(extract_epoch(diff_fn).as('total_time'), *@stage_class.projections).order(@stage_class.order.desc)
      end

      def extract_epoch(arel_attribute)
        return arel_attribute unless Gitlab::Database.postgresql?

        Arel.sql(%Q{EXTRACT(EPOCH FROM (#{arel_attribute.to_sql}))})
      end
    end
  end
end
