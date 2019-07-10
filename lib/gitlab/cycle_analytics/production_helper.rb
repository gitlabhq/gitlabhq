# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module ProductionHelper
      def stage_query(project_ids)
        super(project_ids)
          .where(mr_metrics_table[:first_deployed_to_production_at]
          .gteq(options[:from]))
      end
    end
  end
end
