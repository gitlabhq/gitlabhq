# frozen_string_literal: true

module Mutations
  module WorkItems
    module SavedViews
      class Create < BaseMutation
        graphql_name 'WorkItemSavedViewCreate'

        include Mutations::SpamProtection
        include FindsNamespace

        authorize :create_saved_view

        description "Creates a saved view."

        argument :namespace_path,
          GraphQL::Types::ID,
          required: true,
          description: 'Full path of the namespace to create the saved view in.'

        argument :name,
          GraphQL::Types::String,
          required: true,
          description: 'Name of the saved view.'

        argument :description,
          GraphQL::Types::String,
          required: false,
          description: 'Description of the saved view.'

        argument :filters,
          Types::WorkItems::SavedViews::FilterInputType,
          required: true,
          description: 'Filters associated with the saved view.'

        # rubocop:disable Graphql/JSONType -- Matching the input type in the user preferences update mutation
        argument :display_settings,
          GraphQL::Types::JSON,
          required: true,
          description: 'Display settings associated with the saved view.'
        # rubocop:enable Graphql/JSONType

        argument :sort,
          Types::WorkItems::SortEnum,
          required: true,
          description: 'Sort option associated with the saved view.'

        argument :private,
          GraphQL::Types::Boolean,
          required: false,
          default_value: true,
          description: 'Whether the saved view is private. Default is true.'

        field :saved_view,
          ::Types::WorkItems::SavedViews::SavedViewType,
          null: true,
          scopes: [:api],
          description: 'Created saved view.'

        field :errors, [GraphQL::Types::String],
          null: false,
          scopes: [:api],
          description: 'Errors encountered during the mutation.'

        def resolve(namespace_path:, **_attrs)
          authorized_find!(namespace_path)

          { saved_view: nil, errors: [] }
        end
      end
    end
  end
end
