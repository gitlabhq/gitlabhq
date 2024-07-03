# frozen_string_literal: true

module Types
  module WorkItems
    class UnionedWorkItemFilterInputType < BaseInputObject
      graphql_name 'UnionedWorkItemFilterInput'

      argument :assignee_usernames, [GraphQL::Types::String],
        required: false,
        description: 'Filters work items that are assigned to at least one of the given users.'
      argument :author_usernames, [GraphQL::Types::String],
        required: false,
        description: 'Filters work items that are authored by one of the given users.'
      argument :label_names, [GraphQL::Types::String],
        required: false,
        description: 'Filters work items that have at least one of the given labels.'
    end
  end
end
