# frozen_string_literal: true

module Mutations
  module WorkItems
    module SavedViews
      class Update < BaseMutation
        graphql_name 'WorkItemSavedViewUpdate'

        authorize :update_saved_view

        description "Updates a saved view."

        argument :id,
          ::Types::GlobalIDType[::WorkItems::SavedViews::SavedView],
          required: true,
          description: 'Global ID of the saved view.'

        argument :name,
          GraphQL::Types::String,
          required: false,
          description: 'Name of the saved view.'

        argument :description,
          GraphQL::Types::String,
          required: false,
          description: 'Description of the saved view.'

        argument :filters,
          Types::WorkItems::SavedViews::FilterInputType,
          required: false,
          description: 'Filters associated with the saved view.'

        # rubocop:disable Graphql/JSONType -- Matching the input type in the user preferences update mutation
        argument :display_settings,
          GraphQL::Types::JSON,
          required: false,
          description: 'Display settings associated with the saved view.'
        # rubocop:enable Graphql/JSONType

        argument :sort,
          Types::WorkItems::SortEnum,
          required: false,
          description: 'Sorting option associated with the saved view.'

        argument :private,
          GraphQL::Types::Boolean,
          required: false,
          description: 'Whether the saved view is private.'

        field :saved_view,
          ::Types::WorkItems::SavedViews::SavedViewType,
          null: true,
          scopes: [:api],
          description: 'Updated saved view.'

        field :errors,
          [GraphQL::Types::String],
          null: false,
          scopes: [:api],
          description: 'Errors encountered during the mutation.'

        def resolve(id:, **_attrs)
          authorized_find!(id: id)

          { saved_view: nil, errors: [] }
        end
      end
    end
  end
end
