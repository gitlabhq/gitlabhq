# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module CodeHelper
      def stage_query(project_ids)
        super(project_ids).where(mr_table[:created_at].gteq(issue_metrics_table[:first_mentioned_in_commit_at]))
      end
    end
  end
end
