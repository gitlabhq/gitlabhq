# frozen_string_literal: true

module Types
  module PermissionTypes
    class AbuseReport < BasePermissionType
      graphql_name 'AbuseReportPermissions'

      abilities :read_abuse_report, :create_note
    end
  end
end
