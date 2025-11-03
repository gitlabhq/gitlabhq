# frozen_string_literal: true

module Users
  class ProjectStudio
    # Convenience class method for checking if Project Studio is enabled for a user.
    def self.enabled_for_user?(user, studio_cookie: nil)
      new(user, studio_cookie: studio_cookie).enabled?
    end

    def initialize(user, studio_cookie: nil)
      @user = user
      @studio_cookie = studio_cookie
    end

    def enabled?
      return true if ENV["GLCI_OVERRIDE_PROJECT_STUDIO_ENABLED"] == "true"

      return enabled_for_unsigned_in_user? if user.nil?

      # Project Studio is only enabled for the user if it's available,
      # regardless of their preference
      available? && user.project_studio_enabled
    end

    def available?
      return true if ENV["GLCI_OVERRIDE_PROJECT_STUDIO_ENABLED"] == "true"

      return enabled_for_unsigned_in_user? if user.nil?

      # Project Studio is available for the Early Access Program's members if the
      # `project_studio_early_access` feature flag is enabled.
      return true if has_early_access?

      Feature.enabled?(:paneled_view, user)
    end

    private

    attr_reader :user, :studio_cookie

    def enabled_for_unsigned_in_user?
      studio_cookie == 'true'
    end

    def has_early_access?
      user.user_preference.early_access_studio_participant? && Feature.enabled?(:project_studio_early_access, user)
    end
  end
end
