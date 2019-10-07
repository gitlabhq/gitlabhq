# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module IssueHelper
      def stage_query(project_ids)
        query = issue_table.join(issue_metrics_table).on(issue_table[:id].eq(issue_metrics_table[:issue_id]))
          .join(projects_table).on(issue_table[:project_id].eq(projects_table[:id]))
          .join(routes_table).on(projects_table[:namespace_id].eq(routes_table[:source_id]))
          .project(issue_table[:project_id].as("project_id"))
          .project(projects_table[:path].as("project_path"))
          .project(routes_table[:path].as("namespace_path"))

        query = limit_query(query, project_ids)
        limit_query_by_date_range(query)
      end

      def limit_query(query, project_ids)
        query.where(issue_table[:project_id].in(project_ids))
          .where(routes_table[:source_type].eq('Namespace'))
          .where(issue_metrics_table[:first_added_to_board_at].not_eq(nil).or(issue_metrics_table[:first_associated_with_milestone_at].not_eq(nil)))
      end
    end
  end
end
