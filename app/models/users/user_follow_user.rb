# frozen_string_literal: true
module Users
  class UserFollowUser < ApplicationRecord
    MAX_FOLLOWEE_LIMIT = 300

    belongs_to :follower, class_name: 'User'
    belongs_to :followee, class_name: 'User'

    validate :max_follow_limit

    private

    def max_follow_limit
      followee_count = self.class.where(follower_id: follower_id).limit(MAX_FOLLOWEE_LIMIT).count
      return if followee_count < MAX_FOLLOWEE_LIMIT

      errors.add(
        :base,
        format(
          _("You can't follow more than %{limit} users. To follow more users, unfollow some others."),
          limit: MAX_FOLLOWEE_LIMIT
        )
      )
    end
  end
end
