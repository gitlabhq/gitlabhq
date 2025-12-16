# frozen_string_literal: true

module Types
  module WorkItems
    module SavedViews
      class UnionedFilterInputType < BaseInputObject
        graphql_name 'WorkItemSavedViewUnionedFilterInput'

        argument :assignee_usernames,
          [GraphQL::Types::String],
          required: false,
          validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
          description: "Filter value for unioned assignee usernames filter. " \
            "(maximum is #{::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} usernames)."
        argument :author_usernames,
          [GraphQL::Types::String],
          required: false,
          validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
          description: "Filter value for unioned author usernames filter. " \
            "(maximum is #{::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} usernames)."
        argument :label_names,
          [GraphQL::Types::String],
          required: false,
          validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
          description: "Filter value for unioned label names filter." \
            "(maximum is #{::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} labels)."
      end
    end
  end
end

Types::WorkItems::SavedViews::UnionedFilterInputType.prepend_mod
