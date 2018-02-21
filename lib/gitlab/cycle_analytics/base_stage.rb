module Gitlab
  module CycleAnalytics
    class BaseStage
      include BaseQuery

      def initialize(project:, options:)
        @project = project
        @options = options
      end

      def events
        event_fetcher.fetch
      end

      def as_json
        AnalyticsStageSerializer.new.represent(self)
      end

      def title
        raise NotImplementedError.new("Expected #{self.name} to implement title")
      end

      def median
        BatchLoader.for(@project.id).batch(key: name) do |project_ids, loader|
          cte_table = Arel::Table.new("cte_table_for_#{name}")

          # Build a `SELECT` query. We find the first of the `end_time_attrs` that isn't `NULL` (call this end_time).
          # Next, we find the first of the start_time_attrs that isn't `NULL` (call this start_time).
          # We compute the (end_time - start_time) interval, and give it an alias based on the current
          # cycle analytics stage.
          interval_query = Arel::Nodes::As.new(cte_table,
            subtract_datetimes(stage_query(project_ids), start_time_attrs, end_time_attrs, name.to_s))

          if project_ids.one?
            loader.call(@project.id, median_datetime(cte_table, interval_query, name))
          else
            begin
              median_datetimes(cte_table, interval_query, name, :project_id)&.each do |project_id, median|
                loader.call(project_id, median)
              end
            rescue NotSupportedError
              {}
            end
          end
        end
      end

      def name
        raise NotImplementedError.new("Expected #{self.name} to implement name")
      end

      private

      def event_fetcher
        @event_fetcher ||= Gitlab::CycleAnalytics::EventFetcher[name].new(project: @project,
                                                                          stage: name,
                                                                          options: event_options)
      end

      def event_options
        @options.merge(start_time_attrs: start_time_attrs, end_time_attrs: end_time_attrs)
      end
    end
  end
end
