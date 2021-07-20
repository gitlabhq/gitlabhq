# frozen_string_literal: true

module API
  module Entities
    class User < UserBasic
      include UsersHelper
      expose :created_at, if: ->(user, opts) { Ability.allowed?(opts[:current_user], :read_user_profile, user) }
      expose :bio, :bio_html, :location, :public_email, :skype, :linkedin, :twitter, :website_url, :organization, :job_title, :pronouns
      expose :bot?, as: :bot
      expose :work_information do |user|
        work_information(user)
      end
      expose :followers, if: ->(user, opts) { Ability.allowed?(opts[:current_user], :read_user_profile, user) } do |user|
        user.followers.size
      end
      expose :following, if: ->(user, opts) { Ability.allowed?(opts[:current_user], :read_user_profile, user) } do |user|
        user.followees.size
      end
    end
  end
end
