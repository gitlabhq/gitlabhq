# frozen_string_literal: true

module Types
  module PermissionTypes
    class Snippet < BasePermissionType
      graphql_name 'SnippetPermissions'

      abilities :create_note, :award_emoji

      permission_field :read_snippet, method: :can_read_snippet?
      permission_field :update_snippet, method: :can_update_snippet?
      permission_field :admin_snippet, method: :can_admin_snippet?
      permission_field :report_snippet, method: :can_report_as_spam?
    end
  end
end
