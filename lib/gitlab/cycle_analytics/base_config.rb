module Gitlab
  module CycleAnalytics
    class BaseConfig
      extend MetricsFetcher

      class << self
        attr_reader :start_time_attrs, :end_time_attrs, :projections
      end

      def self.order
        @order || @start_time_attrs
      end

      def self.query(base_query); end
    end
  end
end
