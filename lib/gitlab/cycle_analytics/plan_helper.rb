# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module PlanHelper
      def stage_query(project_ids)
        query = issue_table.join(issue_metrics_table).on(issue_table[:id].eq(issue_metrics_table[:issue_id]))
          .join(projects_table).on(issue_table[:project_id].eq(projects_table[:id]))
          .join(routes_table).on(projects_table[:namespace_id].eq(routes_table[:source_id]))
          .project(issue_table[:project_id].as("project_id"))
          .where(issue_table[:project_id].in(project_ids))
          .where(routes_table[:source_type].eq('Namespace'))
        query = add_conditions_to_query(query)

        query
      end

      def add_conditions_to_query(query)
        query.where(issue_table[:created_at].gteq(options[:from]))
          .where(issue_metrics_table[:first_added_to_board_at].not_eq(nil).or(issue_metrics_table[:first_associated_with_milestone_at].not_eq(nil)))
          .where(issue_metrics_table[:first_mentioned_in_commit_at].not_eq(nil))
      end
    end
  end
end
