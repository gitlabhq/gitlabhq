# frozen_string_literal: true

module Mutations
  module WorkItems
    module SavedViews
      class Subscribe < BaseMutation
        graphql_name 'WorkItemSavedViewSubscribe'

        authorize :read_saved_view

        description "Subscribes the current user to a saved view."

        argument :id,
          ::Types::GlobalIDType[::WorkItems::SavedViews::SavedView],
          required: true,
          description: 'Global ID of the saved view to subscribe to.'

        field :saved_view,
          ::Types::WorkItems::SavedViews::SavedViewType,
          null: true,
          scopes: [:api],
          description: 'Subscribed saved view.'

        field :errors,
          [GraphQL::Types::String],
          null: false,
          scopes: [:api],
          description: 'Errors encountered during the mutation.'

        def resolve(id:)
          authorized_find!(id: id)

          { saved_view: nil, errors: [] }
        end
      end
    end
  end
end
