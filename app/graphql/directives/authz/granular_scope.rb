# frozen_string_literal: true

module Directives
  module Authz
    class GranularScope < GraphQL::Schema::Directive
      repeatable true

      argument :permissions, [GraphQL::Types::String],
        required: false,
        description: 'Granular scope permissions required to access the field or type.'

      argument :boundary_type, Types::Authz::AccessTokens::BoundaryEnum,
        required: false,
        description: 'The type of authorization boundary (project, group, user, instance). ' \
          'Used for validation and documentation of the permission boundary.'

      argument :skip_reason, GraphQL::Types::String,
        required: false,
        description: 'Reason the field or type intentionally opts out of granular token authorization. '

      argument :boundary, GraphQL::Types::String,
        required: false,
        description: 'Method name to call on the resolved object to extract the authorization boundary ' \
          '(Project/Group). Use when the object is already resolved (fields on types, nested fields).'

      argument :boundary_argument, GraphQL::Types::String,
        required: false,
        description: 'Argument name containing the authorization boundary (path or GlobalID). ' \
          'Use for mutations and query fields where the boundary is passed as an argument.'

      argument :requirement_group, GraphQL::Types::String,
        required: false,
        description: 'Label grouping directives that are alternative boundaries for the same ' \
          'requirement. The token must be authorized on any one boundary in a group, and on every ' \
          'group. Absent means the primary group. Set for a second container, such as a move target.'

      locations FIELD_DEFINITION, OBJECT
    end
  end
end
