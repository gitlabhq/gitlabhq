# frozen_string_literal: true

module Authz
  class Permission
    include Authz::Concerns::YamlPermission

    BASE_PATH = 'config/authz/permissions'

    class << self
      def config_path
        Rails.root.join(BASE_PATH, '**/*.yml')
      end
    end
  end
end
