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

      return false unless available?

      return true if user.project_studio_enabled # allow us to control those already in vs everyone else below

      return true if Feature.enabled?(:new_ui_dot_com_rollout, user) && user.new_ui_enabled.nil? && Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- We need this check to enable the new UI by default for all users on .com only

      !!user.new_ui_enabled
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
