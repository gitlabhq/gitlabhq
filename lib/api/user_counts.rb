# frozen_string_literal: true

module API
  class UserCounts < ::API::Base
    feature_category :navigation

    resource :user_counts do
      desc 'Return the user specific counts' do
        detail 'Assigned open issues, assigned MRs and pending todos count'
      end
      get do
        unauthorized! unless current_user

        {
          merge_requests: current_user.assigned_open_merge_requests_count, # @deprecated
          assigned_issues: current_user.assigned_open_issues_count,
          assigned_merge_requests: current_user.assigned_open_merge_requests_count,
          review_requested_merge_requests: current_user.review_requested_open_merge_requests_count,
          todos: current_user.todos_pending_count
        }
      end
    end
  end
end
