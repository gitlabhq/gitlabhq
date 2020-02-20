# frozen_string_literal: true

module API
  module Entities
    class User < UserBasic
      expose :created_at, if: ->(user, opts) { Ability.allowed?(opts[:current_user], :read_user_profile, user) }
      expose :bio, :location, :public_email, :skype, :linkedin, :twitter, :website_url, :organization
    end
  end
end
