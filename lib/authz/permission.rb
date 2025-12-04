# frozen_string_literal: true

module Authz
  class Permission
    include Authz::Concerns::YamlPermission

    class << self
      private

      def config_path
        Rails.root.join("config/authz/permissions/**/*.yml")
      end
    end
  end
end
