# frozen_string_literal: true

module Mutations
  module WorkItems
    module SavedViews
      class Delete < BaseMutation
        graphql_name 'WorkItemSavedViewDelete'

        authorize :delete_saved_view

        description "Deletes a saved view."

        argument :id,
          ::Types::GlobalIDType[::WorkItems::SavedViews::SavedView],
          required: true,
          description: 'Global ID of the saved view.'

        field :saved_view,
          ::Types::WorkItems::SavedViews::SavedViewType,
          null: true,
          scopes: [:api],
          description: 'Deleted saved view.'

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
