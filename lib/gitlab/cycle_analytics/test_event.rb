module Gitlab
  module CycleAnalytics
    class TestEvent < BaseEvent
      @stage = :test
      @start_time_attrs =  mr_metrics_table[:latest_build_started_at]
      @end_time_attrs = mr_metrics_table[:latest_build_finished_at]
      @projections = [build_table[:id]]
      @order = build_table[:created_at]

      def self.query(base_query)
        base_query.join(build_table).on(mr_metrics_table[:pipeline_id].eq(build_table[:commit_id]))
      end

      def self.serialize(event, _query)
        build = ::Ci::Build.find(event['id'])

        AnalyticsBuildSerializer.new.represent(build).as_json
      end
    end
  end
end
