module Gitlab
  module CycleAnalytics
    class BaseEvent
      extend MetricsTables

      class << self
        attr_reader :stage, :start_time_attrs, :end_time_attrs, :projections

        def order
          @order || @start_time_attrs
        end

        def query(_base_query); end

        def fetch(query)
          query.execute(self).map { |event| serialize(event, query) }
        end

        private

        def serialize(_event, _query)
          raise NotImplementedError.new("Expected #{self.name} to implement serialize(event, query)")
        end
      end
    end
  end
end
