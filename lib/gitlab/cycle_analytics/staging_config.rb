module Gitlab
  module CycleAnalytics
    class StagingConfig < BaseConfig
      @start_time_attrs = mr_metrics_table[:merged_at]
      @end_time_attrs = mr_metrics_table[:first_deployed_to_production_at]
      @projections = [build_table[:id]]
      @order = build_table[:created_at]

      def self.query(base_query)
        base_query.join(build_table).on(mr_metrics_table[:pipeline_id].eq(build_table[:commit_id]))
      end
    end
  end
end
