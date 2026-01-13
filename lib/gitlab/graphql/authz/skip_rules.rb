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

          mutation_response_field? || permission_metadata_field?
        end

        private

        # Mutation response fields (e.g., `createIssue.issue`)
        # Authorization happens on the mutation field itself, not the response wrapper
        def mutation_response_field?
          !!(@owner <= ::Mutations::BaseMutation)
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
