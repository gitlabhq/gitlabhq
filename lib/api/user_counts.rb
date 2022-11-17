# frozen_string_literal: true

module API
  class UserCounts < ::API::Base
    feature_category :navigation
    urgency :low

    resource :user_counts do
      desc 'Return the user specific counts' do
        detail 'Assigned open issues, assigned MRs and pending todos count'
        success Entities::UserCounts
      end
      get do
        unauthorized! unless current_user

        present current_user, with: Entities::UserCounts
      end
    end
  end
end
