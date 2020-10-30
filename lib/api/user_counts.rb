# frozen_string_literal: true

module API
  class UserCounts < ::API::Base
    feature_category :navigation

    resource :user_counts do
      desc 'Return the user specific counts' do
        detail 'Open MR Count'
      end
      get do
        unauthorized! unless current_user

        {
          merge_requests: current_user.assigned_open_merge_requests_count
        }
      end
    end
  end
end
