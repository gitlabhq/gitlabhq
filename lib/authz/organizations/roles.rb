# frozen_string_literal: true

module Authz
  module Organizations
    # Resolves the Organization Administrator platform role to its glaz-roles
    # id by its stable key; the gem memoizes the catalogue itself.
    module Roles
      require 'gitlab/glaz'

      ORGANIZATION_ADMIN_KEY = 'organization_admin'

      def self.organization_admin_uuid
        ::Gitlab::Glaz.roles.find { |role| role[:key] == ORGANIZATION_ADMIN_KEY }&.fetch(:id)
      end
    end
  end
end
