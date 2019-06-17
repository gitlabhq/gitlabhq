# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module ReviewHelper
      def stage_query(project_ids)
        super(project_ids).where(mr_metrics_table[:merged_at].not_eq(nil))
      end
    end
  end
end
