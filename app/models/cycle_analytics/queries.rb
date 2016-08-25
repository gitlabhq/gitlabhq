class CycleAnalytics
  module Queries
    class << self
      def issue_first_associated_with_milestone_or_first_added_to_list_label_time
        lambda do |issue|
          issue.metrics.first_associated_with_milestone_at.presence || issue.metrics.first_added_to_board_at.presence
        end
      end

      def issue_closing_merge_request_opened_time
        lambda do |issue|
          merge_requests = issue.closed_by_merge_requests
          merge_requests.map(&:created_at).min if merge_requests.present?
        end
      end

      def mr_wip_flag_removed_or_assigned_to_user_other_than_author_time
        lambda do |merge_request|
          if merge_request.metrics.present?
            merge_request.metrics.wip_flag_first_removed_at || merge_request.metrics.first_assigned_to_user_other_than_author
          end
        end
      end
    end
  end
end
