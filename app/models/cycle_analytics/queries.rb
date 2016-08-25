class CycleAnalytics
  module Queries
    class << self
      def issue_first_associated_with_milestone_or_first_added_to_list_label_time
        lambda do |issue|
          if issue.metrics.present?
            issue.metrics.first_associated_with_milestone_at.presence ||
              issue.metrics.first_added_to_board_at.presence
          end
        end
      end

      def mr_first_closed_or_merged_at
        lambda do |merge_request|
          if merge_request.metrics.present?
            merge_request.metrics.merged_at.presence || merge_request.metrics.first_closed_at.presence
          end
        end
      end

      def issue_closing_merge_request_opened_time
        lambda do |issue|
          merge_requests = issue.closed_by_merge_requests(nil, check_if_open: false)
          merge_requests.map(&:created_at).min if merge_requests.present?
        end
      end

      def mr_wip_flag_removed_or_assigned_to_user_other_than_author_time
        lambda do |merge_request|
          if merge_request.metrics.present?
            merge_request.metrics.wip_flag_first_removed_at.presence ||
              merge_request.metrics.first_assigned_to_user_other_than_author.presence
          end
        end
      end
    end
  end
end
