# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class BaseStage
      include BaseQuery
      include BaseDataExtraction

      attr_reader :options

      def initialize(options:)
        @options = options
      end

      def events
        event_fetcher.fetch
      end

      def as_json(serializer: AnalyticsStageSerializer)
        serializer.new.represent(self)
      end

      def title
        raise NotImplementedError.new("Expected #{self.name} to implement title")
      end

      def project_median
        return if project.nil?

        BatchLoader.for(project.id).batch(key: name) do |project_ids, loader|
          if project_ids.one?
            loader.call(project.id, median_query(project_ids))
          else
            begin
              median_datetimes(cte_table, interval_query(project_ids), name, :project_id)&.each do |project_id, median|
                loader.call(project_id, median)
              end
            rescue NotSupportedError
              {}
            end
          end
        end
      end

      def group_median
        median_query(projects.map(&:id))
      end

      def median_query(project_ids)
        # Build a `SELECT` query. We find the first of the `end_time_attrs` that isn't `NULL` (call this end_time).
        # Next, we find the first of the start_time_attrs that isn't `NULL` (call this start_time).
        # We compute the (end_time - start_time) interval, and give it an alias based on the current
        # cycle analytics stage.

        median_datetime(cte_table, interval_query(project_ids), name)
      end

      def name
        raise NotImplementedError.new("Expected #{self.name} to implement name")
      end

      def cte_table
        Arel::Table.new("cte_table_for_#{name}")
      end

      def interval_query(project_ids)
        Arel::Nodes::As.new(cte_table,
          subtract_datetimes(stage_query(project_ids), start_time_attrs, end_time_attrs, name.to_s))
      end

      private

      def event_fetcher
        @event_fetcher ||= Gitlab::CycleAnalytics::EventFetcher[name].new(stage: name,
                                                                          options: event_options)
      end

      def event_options
        options.merge(start_time_attrs: start_time_attrs, end_time_attrs: end_time_attrs)
      end
    end
  end
end
