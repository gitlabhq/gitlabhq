module Gitlab
  module CycleAnalytics
    class StagingEvent < BaseEvent
      def initialize(*args)
        @stage = :staging
        @start_time_attrs = mr_metrics_table[:merged_at]
        @end_time_attrs = mr_metrics_table[:first_deployed_to_production_at]
        @projections = [build_table[:id]]
        @order = build_table[:created_at]

        super(*args)
      end

      def custom_query(base_query)
        base_query.join(build_table).on(mr_metrics_table[:pipeline_id].eq(build_table[:commit_id]))
      end

      private

      def serialize(event)
        build = ::Ci::Build.find(event['id'])

        AnalyticsBuildSerializer.new.represent(build).as_json
      end
    end
  end
end
