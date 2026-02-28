# frozen_string_literal: true

module Authz
  module PermissionGroups
    class Base
      include Authz::Concerns::YamlPermission
      include Gitlab::Utils::StrongMemoize

      def permissions
        @permissions ||= Array(definition[:permissions]).map(&:to_sym).uniq
      end
    end
  end
end
