# frozen_string_literal: true

module API
  class UserCounts < ::API::Base
    feature_category :navigation
    urgency :low

    resource :user_counts do
      desc 'Return the user specific counts' do
        detail 'Assigned open issues, assigned MRs and pending todos count'
        success Entities::UserCounts
        tags ['users']
      end
      route_setting :authorization, permissions: :read_user_counts, boundary_type: :user
      get do
        unauthorized! unless current_user

        present current_user, with: Entities::UserCounts
      end
    end
  end
end
