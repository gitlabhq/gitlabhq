# frozen_string_literal: true

module Users
  # Service class for getting the number of SSH keys that belong to a user.
  class KeysCountService < BaseCountService
    attr_reader :user

    # user - The User for which to get the number of SSH keys.
    def initialize(user)
      @user = user
    end

    def relation_for_count
      user.keys.auth
    end

    def raw?
      # Since we're storing simple integers we don't need all of the additional
      # Marshal data Rails includes by default.
      true
    end

    def cache_key
      "users/key-count-service/#{user.id}"
    end
  end
end
