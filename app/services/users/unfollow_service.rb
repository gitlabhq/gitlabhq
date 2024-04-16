# frozen_string_literal: true

module Users
  class UnfollowService
    def initialize(params)
      @follower = params[:follower]
      @followee = params[:followee]
    end

    def execute
      # rubocop: disable CodeReuse/ActiveRecord -- This is special service for unfollowing users
      deleted_rows = Users::UserFollowUser.where(
        follower_id: @follower.id,
        followee_id: @followee.id
      ).delete_all
      # rubocop: enable CodeReuse/ActiveRecord

      if deleted_rows > 0
        @follower.followees.reset
        ServiceResponse.success
      else
        ServiceResponse.error(message: _('Failed to unfollow user'))
      end
    end
  end
end
