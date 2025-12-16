# frozen_string_literal: true

module Mutations
  module WorkItems
    module SavedViews
      class Reorder < BaseMutation
        graphql_name 'WorkItemSavedViewReorder'

        authorize :read_saved_view

        description "Reorders a saved view for the current user."

        argument :id,
          ::Types::GlobalIDType[::WorkItems::SavedViews::SavedView],
          required: true,
          description: 'Global ID of the saved view to be reordered.'

        argument :move_before_id,
          ::Types::GlobalIDType[::WorkItems::SavedViews::SavedView],
          required: false,
          description: 'Global ID of a saved view that should be placed before the saved view.',
          prepare: ->(id, _ctx) { GitlabSchema.parse_gid(id).model_id }

        argument :move_after_id,
          ::Types::GlobalIDType[::WorkItems::SavedViews::SavedView],
          required: false,
          description: 'Global ID of a saved view that should be placed after the saved view.',
          prepare: ->(id, _ctx) { GitlabSchema.parse_gid(id).model_id }

        field :saved_view,
          ::Types::WorkItems::SavedViews::SavedViewType,
          null: true,
          scopes: [:api],
          description: 'Reordered saved view.'

        field :errors,
          [GraphQL::Types::String],
          null: false,
          scopes: [:api],
          description: 'Errors encountered during the mutation.'

        validates mutually_exclusive: [:move_before_id, :move_after_id]

        def resolve(id:, **_args)
          authorized_find!(id: id)

          { saved_view: nil, errors: [] }
        end
      end
    end
  end
end
