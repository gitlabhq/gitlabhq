# frozen_string_literal: true

module Users
  class UpdateHighestMemberRoleService < BaseService
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def execute
      return true if user_highest_role.persisted? && highest_access_level == user_highest_role.highest_access_level

      user_highest_role.update!(highest_access_level: highest_access_level)
    end

    private

    def user_highest_role
      @user_highest_role ||= @user.user_highest_role || @user.build_user_highest_role
    end

    def highest_access_level
      @highest_access_level ||= @user.current_highest_access_level
    end
  end
end
