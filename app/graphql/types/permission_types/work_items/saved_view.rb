# frozen_string_literal: true

module Types
  module PermissionTypes
    module WorkItems
      class SavedView < BasePermissionType
        graphql_name 'SavedViewPermissions'
        description 'Check permissions for the current user on a saved view'

        abilities :read_saved_view, :update_saved_view, :delete_saved_view, :update_saved_view_visibility
      end
    end
  end
end
