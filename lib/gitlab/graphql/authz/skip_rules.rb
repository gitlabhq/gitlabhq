# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      # Determines whether granular token authorization should be skipped for a field
      class SkipRules
        include TypeUnwrapper

        def initialize(field)
          @field = field
          @owner = field.owner
        end

        def should_skip?
          return false unless @owner.is_a?(Class)

          mutation_response_field? || permission_metadata_field? || edge_wrapper_field?
        end

        private

        # Mutation response fields (e.g., `createIssue.issue`)
        # Authorization happens on the mutation field itself, not the response wrapper
        def mutation_response_field?
          !!(@owner <= ::Mutations::BaseMutation)
        end

        # Edge wrapper fields (e.g., `node`, `cursor`)
        # Types::BaseEdge sets field_class to Types::BaseField, so the
        # extension fires on edge fields. The `node` field picks up
        # directives via return-type lookup, but boundary extraction
        # fails because the auto-generated edge class is anonymous.
        # Authorization happens on the actual data type's fields instead.
        def edge_wrapper_field?
          !!(@owner <= ::GraphQL::Types::Relay::BaseEdge)
        end

        # Permission metadata fields (e.g., `issue.userPermissions`)
        # These return permission information, not actual data
        def permission_metadata_field?
          owner_is_permission_type? || return_type_is_permission_type?
        end

        def owner_is_permission_type?
          !!(@owner <= ::Types::PermissionTypes::BasePermissionType)
        end

        def return_type_is_permission_type?
          return_type = unwrap_type(@field.type)
          return false unless return_type.is_a?(Class)

          !!(return_type < ::Types::PermissionTypes::BasePermissionType)
        end
      end
    end
  end
end
