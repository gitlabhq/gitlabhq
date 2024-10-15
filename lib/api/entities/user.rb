# frozen_string_literal: true

module API
  module Entities
    class User < UserBasic
      include ::UsersHelper
      include TimeZoneHelper
      include Gitlab::Utils::StrongMemoize

      expose :created_at, if: ->(user, opts) { Ability.allowed?(opts[:current_user], :read_user_profile, user) }
      expose :bio, :location, :public_email, :skype, :linkedin, :twitter, :discord, :website_url, :organization, :job_title, :pronouns
      expose :bot?, as: :bot
      expose :work_information do |user|
        work_information(user)
      end
      expose :followers, if: ->(user, opts) { Ability.allowed?(opts[:current_user], :read_user_profile, user) && following_users_allowed(opts[:current_user], user) } do |user|
        user.followers.size
      end
      expose :following, if: ->(user, opts) { Ability.allowed?(opts[:current_user], :read_user_profile, user) && following_users_allowed(opts[:current_user], user) } do |user|
        user.followees.size
      end
      expose :is_followed, if: ->(user, opts) { Ability.allowed?(opts[:current_user], :read_user_profile, user) && opts[:current_user] && following_users_allowed(opts[:current_user], user) } do |user, opts|
        user.followed_by?(opts[:current_user])
      end
      expose :local_time do |user|
        local_time(user.timezone)
      end

      def following_users_allowed(current_user, user)
        strong_memoize(:following_users_allowed) do
          if current_user
            current_user.following_users_allowed?(user)
          else
            true
          end
        end
      end
    end
  end
end
