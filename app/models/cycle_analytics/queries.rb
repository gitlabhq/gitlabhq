class CycleAnalytics
  module Queries
    class << self
      def issues
        Issue.all.to_a.map { |issue| { issue: issue } }
      end

      def merge_requests_closing_issues
        issues.map do |data_point|
          merge_requests = data_point[:issue].closed_by_merge_requests(nil, check_if_open: false)
          merge_requests.map { |merge_request| { issue: data_point[:issue], merge_request: merge_request } }
        end.flatten
      end

      def issue_first_associated_with_milestone_or_first_added_to_list_label_time
        lambda do |data_point|
          issue = data_point[:issue]
          if issue.metrics.present?
            issue.metrics.first_associated_with_milestone_at.presence ||
              issue.metrics.first_added_to_board_at.presence
          end
        end
      end

      def mr_first_closed_or_merged_at
        lambda do |data_point|
          merge_request = data_point[:merge_request]
          if merge_request.metrics.present?
            merge_request.metrics.merged_at.presence || merge_request.metrics.first_closed_at.presence
          end
        end
      end

      def mr_merged_at
        lambda do |data_point|
          merge_request = data_point[:merge_request]
          if merge_request.metrics.present?
            merge_request.metrics.merged_at
          end
        end
      end

      def mr_deployed_to_any_environment_at
        lambda do |data_point|
          merge_request = data_point[:merge_request]
          if merge_request.metrics.present?
            deployments = Deployment.where(ref: merge_request.target_branch).where("created_at > ?", merge_request.metrics.merged_at)
            deployment = deployments.order(:created_at).first
            deployment.created_at if deployment
          end
        end
      end

      def mr_deployed_to_production_at
        lambda do |data_point|
          merge_request = data_point[:merge_request]
          if merge_request.metrics.present?
            deployments = Deployment.joins(:environment).where(ref: merge_request.target_branch, "environments.name" => "production").
                          where("deployments.created_at > ?", merge_request.metrics.merged_at)
            deployment = deployments.order(:created_at).first
            deployment.created_at if deployment
          end
        end
      end

      def issue_closing_merge_request_opened_time
        lambda do |data_point|
          issue = data_point[:issue]
          merge_requests = issue.closed_by_merge_requests(nil, check_if_open: false)
          merge_requests.map(&:created_at).min if merge_requests.present?
        end
      end

      def mr_wip_flag_removed_or_assigned_to_user_other_than_author_time
        lambda do |data_point|
          merge_request = data_point[:merge_request]
          if merge_request.metrics.present?
            merge_request.metrics.wip_flag_first_removed_at.presence ||
              merge_request.metrics.first_assigned_to_user_other_than_author.presence
          end
        end
      end
    end
  end
end
