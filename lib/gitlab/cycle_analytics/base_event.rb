module Gitlab
  module CycleAnalytics
    class BaseEvent
      extend MetricsTables

      class << self
        attr_reader :stage, :start_time_attrs, :end_time_attrs, :projections

        def order
          @order || @start_time_attrs
        end

        def query(base_query); end

        def fetch(query)
          query.execute(self).map { |event| serialize(event, query) }
        end

        private

        def serialize(event, query)
          raise NotImplementedError.new("Expected #{self.name} to implement serialize(event)")
        end
      end
    end
  end
end
