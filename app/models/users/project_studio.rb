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
      return true if ENV["GLCI_OVERRIDE_PROJECT_STUDIO_ENABLED"] == "true"

      return false unless available?

      return true if user.nil?

      return true if user.project_studio_enabled # allow us to control those already in vs everyone else below

      return true if user.new_ui_enabled.nil?

      user.new_ui_enabled
    end

    def available?
      return true if ENV["GLCI_OVERRIDE_PROJECT_STUDIO_ENABLED"] == "true"

      Feature.enabled?(:paneled_view, user)
    end

    private

    attr_reader :user
  end
end
