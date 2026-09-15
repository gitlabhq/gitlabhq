# frozen_string_literal: true

module Types
  module PermissionTypes
    module MergeRequests
      class SavedView < BasePermissionType
        graphql_name 'MergeRequestSavedViewPermissions'
        description 'Check permissions for the current user on a merge request saved view'

        authorize_granular_token skip_reason: :parent_authorizes

        abilities :update_saved_view, :delete_saved_view
      end
    end
  end
end
