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
          saved_view = authorized_find!(id: id)

          unless saved_view.namespace.owner_entity.work_items_saved_views_enabled?(current_user)
            return { saved_view: nil, errors: ['Saved views are not enabled for this namespace.'] }
          end

          saved_view.destroy!

          { saved_view: saved_view, errors: [] }
        end

        private

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_type: ::WorkItems::SavedViews::SavedView)
        end
      end
    end
  end
end
