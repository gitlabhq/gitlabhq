# frozen_string_literal: true

module Types
  module PermissionTypes
    module Notes
      class Discussion < BasePermissionType
        graphql_name 'DiscussionPermissions'

        permission_field :resolve_note

        def resolve_note
          object.can_resolve_discussion?(context[:current_user])
        end
      end
    end
  end
end
