# frozen_string_literal: true

module Resolvers
  class GroupIssuesResolver < IssuesResolver
    argument :include_subgroups, GraphQL::BOOLEAN_TYPE,
             required: false,
             default_value: false,
             description: 'Include issues belonging to subgroups.'
  end
end
