# frozen_string_literal: true

module Types
  module PermissionTypes
    class Timelog < BasePermissionType
      graphql_name 'TimelogPermissions'

      abilities :admin_timelog
    end
  end
end
