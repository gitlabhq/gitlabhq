# frozen_string_literal: true

module Types
  module WorkItems
    module SavedViews
      class FilterWarningType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- Parent is already authorized
        graphql_name 'WorkItemSavedViewFilterWarningType'

        field :field,
          GraphQL::Types::String,
          null: false,
          description: 'Name of the field associated with the warning.'

        field :message,
          GraphQL::Types::String,
          null: false,
          description: 'Message associated with the warning.'
      end
    end
  end
end
