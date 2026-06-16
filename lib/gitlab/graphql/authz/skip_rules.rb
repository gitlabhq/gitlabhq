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

          mutation_response_field? ||
            permission_metadata_field? ||
            edge_wrapper_field? ||
            traversal_to_authorized_type?
        end

        private

        # Mutation response fields (e.g., `createIssue.issue`)
        # Authorization happens on the mutation field itself, not the response wrapper
        def mutation_response_field?
          !!(@owner <= ::Mutations::BaseMutation)
        end

        # Traversal fields whose return type already carries its own granular_token
        # directive (e.g., GroupType.groupMembers -> GroupMemberType).
        # Without this skip, every field on an authorized owner type would also
        # demand the owner's permission (e.g., `read_group`) even though the
        # child type's directive already gates any actual data access.
        # Only applies when the field has no own directive: an explicit
        # field-level directive always wins.
        #
        # The skip is only safe when the return type itself has authorized sub-fields
        # (e.g., GroupMemberType -> UserType). Those deeper fields will run their own
        # service check. For leaf return types (all scalar fields), we must not skip
        # because an empty collection would leave the check unfired.
        def traversal_to_authorized_type?
          return false if field_has_own_directive?
          return false unless owner_has_directive?
          return false unless return_type_has_directive?

          return_type_has_deeper_authorized_fields?
        end

        def field_has_own_directive?
          granular_scope_directives_on(@field).any?
        end

        def owner_has_directive?
          granular_scope_directives_on(@owner).any?
        end

        def return_type_has_directive?
          granular_scope_directives_on(unwrap_type(@field.type)).any?
        end

        def return_type_has_deeper_authorized_fields?
          rt = unwrap_type(@field.type)
          return false unless rt.respond_to?(:fields)

          rt.fields.any? { |_name, f| granular_scope_directives_on(unwrap_type(f.type)).any? }
        end

        def granular_scope_directives_on(field_or_type)
          return [] unless field_or_type.respond_to?(:directives)

          field_or_type.directives.select { |d| d.is_a?(Directives::Authz::GranularScope) }
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
