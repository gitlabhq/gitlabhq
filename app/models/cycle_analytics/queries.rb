class CycleAnalytics
  module Queries
    class << self
      def issues(project, created_after:)
        project.issues.where("created_at >= ?", created_after).map { |issue| { issue: issue } }
      end

      def merge_requests_closing_issues(project, options = {})
        issues(project, options).map do |data_point|
          merge_requests = data_point[:issue].closed_by_merge_requests(nil, check_if_open: false)
          merge_requests.map { |merge_request| { issue: data_point[:issue], merge_request: merge_request } }
        end.flatten
      end

      def issue_first_associated_with_milestone_at
        lambda do |data_point|
          issue = data_point[:issue]
          issue.metrics.first_associated_with_milestone_at if issue.metrics.present?
        end
      end

      def issue_first_added_to_list_label_at
        lambda do |data_point|
          issue = data_point[:issue]
          issue.metrics.first_added_to_board_at if issue.metrics.present?
        end
      end

      def issue_first_mentioned_in_commit_at
        lambda do |data_point|
          issue = data_point[:issue]
          commits_mentioning_issue = issue.notes.system.map { |note| note.all_references.commits }.flatten
          commits_mentioning_issue.map(&:committed_date).min if commits_mentioning_issue.present?
        end
      end

      def merge_request_first_closed_at
        lambda do |data_point|
          merge_request = data_point[:merge_request]
          merge_request.metrics.first_closed_at if merge_request.metrics.present?
        end
      end

      def merge_request_merged_at
        lambda do |data_point|
          merge_request = data_point[:merge_request]
          merge_request.metrics.merged_at if merge_request.metrics.present?
        end
      end

      def merge_request_build_started_at
        lambda do |data_point|
          merge_request = data_point[:merge_request]
          tip = merge_request.commits.first
          return unless tip

          pipeline = Ci::Pipeline.find_by_sha(tip.sha)
          pipeline.started_at if pipeline
        end
      end

      def merge_request_build_finished_at
        lambda do |data_point|
          merge_request = data_point[:merge_request]
          tip = merge_request.commits.first
          return unless tip

          pipeline = Ci::Pipeline.find_by_sha(tip.sha)
          pipeline.finished_at if pipeline
        end
      end

      def merge_request_deployed_to_any_environment_at
        lambda do |data_point|
          merge_request = data_point[:merge_request]
          if merge_request.metrics.present?
            deployments = Deployment.where(ref: merge_request.target_branch).where("created_at > ?", merge_request.metrics.merged_at)
            deployment = deployments.order(:created_at).first
            deployment.created_at if deployment
          end
        end
      end

      def merge_request_deployed_to_production_at
        lambda do |data_point|
          merge_request = data_point[:merge_request]
          if merge_request.metrics.present?
            # The first production deploy to the target branch that occurs after the merge request has been merged in.
            # TODO: Does this need to account for reverts?
            deployments = Deployment.joins(:environment).where(ref: merge_request.target_branch, "environments.name" => "production").
                          where("deployments.created_at > ?", merge_request.metrics.merged_at)
            deployment = deployments.order(:created_at).first
            deployment.created_at if deployment
          end
        end
      end

      def issue_closing_merge_request_opened_at
        lambda do |data_point|
          issue = data_point[:issue]
          merge_requests = issue.closed_by_merge_requests(nil, check_if_open: false)
          merge_requests.map(&:created_at).min if merge_requests.present?
        end
      end

      def merge_request_wip_flag_first_removed_at
        lambda do |data_point|
          merge_request = data_point[:merge_request]
          merge_request.metrics.wip_flag_first_removed_at if merge_request.metrics.present?
        end
      end

      def merge_request_first_assigned_to_user_other_than_author_at
        lambda do |data_point|
          merge_request = data_point[:merge_request]
          merge_request.metrics.first_assigned_to_user_other_than_author if merge_request.metrics.present?
        end
      end
    end
  end
end
