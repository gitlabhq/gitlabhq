# frozen_string_literal: true

module Types
  module Authz
    class GranularScopePermissionEnum < Types::BaseEnum
      graphql_name 'GranularScopePermission'
      description 'Granular scope permission for granular token authorization'

      ::Authz::PermissionGroups::Assignable.all_permissions.uniq.each do |permission|
        raw_permission = ::Authz::Permission.get(permission)
        # rubocop:disable Gitlab/NoCodeCoverageComment -- this code is run at load time and cannot be tested with mocking
        # :nocov:
        next unless raw_permission

        # :nocov:
        # rubocop:enable Gitlab/NoCodeCoverageComment

        value raw_permission.name.upcase, value: raw_permission.name, description: raw_permission.description
      end
    end
  end
end
