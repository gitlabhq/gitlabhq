# frozen_string_literal: true

module Users
  class ProjectStudio
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

      Feature.enabled?(:paneled_view, user)
    end

    private

    attr_accessor :user
  end
end
