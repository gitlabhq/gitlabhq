# frozen_string_literal: true

module Types
  module WorkItems
    class UnionedWorkItemFilterInputType < BaseInputObject
      graphql_name 'UnionedWorkItemFilterInput'

      argument :assignee_usernames, [GraphQL::Types::String],
        required: false,
        validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
        description: "Filters work items that are assigned to at least one of the given users " \
          "(maximum is #{::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} usernames)."
      argument :author_usernames, [GraphQL::Types::String],
        required: false,
        validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
        description: "Filters work items that are authored by one of the given users " \
          "(maximum is #{::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} usernames)."
      argument :label_names, [GraphQL::Types::String],
        required: false,
        validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
        description: "Filters work items that have at least one of the given labels " \
          "(maximum is #{::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} labels)."
    end
  end
end
