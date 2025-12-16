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
      return false if ENV["GLCI_OVERRIDE_PROJECT_STUDIO_ENABLED"] == "false"

      Feature.enabled?(:paneled_view, user)
    end

    private

    attr_reader :user
  end
end
