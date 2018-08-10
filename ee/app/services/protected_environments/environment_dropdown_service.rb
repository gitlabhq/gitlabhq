# frozen_string_literal: true
module ProtectedEnvironments
  class EnvironmentDropdownService
    def self.roles_hash
      { roles: roles }
    end

    def self.roles
      human_access_levels.map do |id, text|
        { id: id, text: text, before_divider: true }
      end
    end

    def self.human_access_levels
      ::ProtectedEnvironment::DeployAccessLevel::HUMAN_ACCESS_LEVELS
    end
  end
end
