# frozen_string_literal: true

module Directives
  module Authz
    class GranularScope < GraphQL::Schema::Directive
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

      locations FIELD_DEFINITION, OBJECT
    end
  end
end
