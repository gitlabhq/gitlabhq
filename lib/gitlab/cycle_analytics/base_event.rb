module Gitlab
  module CycleAnalytics
    class BaseEvent
      include MetricsTables

      attr_reader :stage, :start_time_attrs, :end_time_attrs, :projections, :query

      def initialize(project:, options:)
        @query = EventsQuery.new(project: project, options: options)
        @project = project
        @options = options
      end

      def fetch
        @query.execute(self).map do |event|
          serialize(event) if has_permission?(event['id'])
        end
      end

      def custom_query(_base_query); end

      def order
        @order || @start_time_attrs
      end

      private

      def serialize(_event)
        raise NotImplementedError.new("Expected #{self.name} to implement serialize(event)")
      end

      def has_permission?(_id)
        true
      end
    end
  end
end
