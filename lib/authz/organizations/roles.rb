# frozen_string_literal: true

module Authz
  module Organizations
    # Resolves the Organization Administrator platform role to its glaz-roles
    # id. Gitlab::Glaz.roles exposes only a display name and id, hence the
    # lookup by name; the gem memoizes the catalogue itself.
    module Roles
      require 'gitlab/glaz'

      ORGANIZATION_ADMIN_NAME = 'Organization Administrator'

      def self.organization_admin_uuid
        ::Gitlab::Glaz.roles.find { |role| role[:name] == ORGANIZATION_ADMIN_NAME }&.fetch(:id)
      end
    end
  end
end
