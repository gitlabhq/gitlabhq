# frozen_string_literal: true

module Authz
  class PermissionGroup
    include Authz::Concerns::YamlPermission

    class << self
      private

      def config_path
        Rails.root.join("config/authz/permission_groups/**/*.yml")
      end
    end

    def permissions
      definition[:permissions].map(&:to_sym).sort.uniq
    end
  end
end
