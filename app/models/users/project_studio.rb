# frozen_string_literal: true

module Users
  class ProjectStudio
    # Convenience class method for checking if Project Studio is enabled for a user.
    def self.enabled_for_user?(user)
      new(user).enabled?
    end

    def initialize(user)
      @user = user
    end

    def enabled?
      return false if user.nil?

      # Project Studio is only enabled for the user if it's available,
      # regardless of their preference
      available? && user.project_studio_enabled
    end

    def available?
      return false if user.nil?

      # Project Studio is available for the Early Access Program's members if the
      # `project_studio_early_access` feature flag is enabled.
      return true if has_early_access?

      Feature.enabled?(:paneled_view, user)
    end

    private

    attr_accessor :user

    def has_early_access?
      user.user_preference.early_access_studio_participant? && Feature.enabled?(:project_studio_early_access, user)
    end
  end
end
