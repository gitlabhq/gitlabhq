# frozen_string_literal: true

module Mutations
  module WorkItems
    module SavedViews
      class Unsubscribe < BaseMutation
        graphql_name 'WorkItemSavedViewUnsubscribe'

        authorize :read_saved_view

        description "Unsubscribes the current user to a saved view."

        argument :id,
          ::Types::GlobalIDType[::WorkItems::SavedViews::SavedView],
          required: true,
          description: 'Global ID of the saved view to unsubscribe to.'

        field :saved_view,
          ::Types::WorkItems::SavedViews::SavedViewType,
          null: true,
          scopes: [:api],
          description: 'Unsubscribed saved view.'

        def resolve(id:)
          authorized_find!(id: id)

          { saved_view: nil }
        end
      end
    end
  end
end
