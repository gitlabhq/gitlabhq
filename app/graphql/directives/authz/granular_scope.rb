# frozen_string_literal: true

module Directives
  module Authz
    class GranularScope < GraphQL::Schema::Directive
      repeatable true

      argument :permissions, [GraphQL::Types::String],
        description: 'Granular scope permissions required to access the field or type.'

      argument :boundary_type, Types::Authz::AccessTokens::BoundaryEnum,
        description: 'The type of authorization boundary (project, group, user, instance). ' \
          'Used for validation and documentation of the permission boundary.'

      argument :boundary, GraphQL::Types::String,
        required: false,
        description: 'Method name to call on the resolved object to extract the authorization boundary ' \
          '(Project/Group). Use when the object is already resolved (fields on types, nested fields).'

      argument :boundary_argument, GraphQL::Types::String,
        required: false,
        description: 'Argument name containing the authorization boundary (path or GlobalID). ' \
          'Use for mutations and query fields where the boundary is passed as an argument.'

      argument :traversal, GraphQL::Types::Boolean,
        required: false,
        description: 'When true, this directive only verifies the token is scoped to the boundary ' \
          '(read_boundary), without enforcing the listed permissions. Use for entry-point fields ' \
          'like Query.group(fullPath:) where downstream fields enforce the real permissions. ' \
          'Only applies to project and group boundary types. All other boundary types ' \
          'fall back to the regular permission check.'

      locations FIELD_DEFINITION, OBJECT
    end
  end
end
