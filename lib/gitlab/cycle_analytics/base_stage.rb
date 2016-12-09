module Gitlab
  module CycleAnalytics
    class BaseStage
      include BaseQuery

      def initialize(project:, options:)
        @project = project
        @options = options
      end

      def event
        @event ||= Gitlab::CycleAnalytics::Event[name].new(project: @project,
                                                           stage: name,
                                                           options: event_options)
      end

      def events
        event.fetch
      end

      def median_data
        AnalyticsStageSerializer.new.represent(self).as_json
      end

      def title
        name.to_s.capitalize
      end

      def median
        cte_table = Arel::Table.new("cte_table_for_#{name}")

        # Build a `SELECT` query. We find the first of the `end_time_attrs` that isn't `NULL` (call this end_time).
        # Next, we find the first of the start_time_attrs that isn't `NULL` (call this start_time).
        # We compute the (end_time - start_time) interval, and give it an alias based on the current
        # cycle analytics stage.
        interval_query = Arel::Nodes::As.new(
          cte_table,
          subtract_datetimes(base_query.dup, @start_time_attrs, @end_time_attrs, name.to_s))

        median_datetime(cte_table, interval_query, name)
      end

      def name
        raise NotImplementedError.new("Expected #{self.name} to implement name")
      end

      private

      def event_options
        @options.merge(start_time_attrs: @start_time_attrs, end_time_attrs: @end_time_attrs)
      end
    end
  end
end
