# frozen_string_literal: true

module Mutations
  module WorkItems
    module SavedViews
      class Unsubscribe < BaseMutation
        graphql_name 'WorkItemSavedViewUnsubscribe'

        authorize :read_saved_view

        description "Unsubscribes the current user from a saved view."

        argument :id,
          ::Types::GlobalIDType[::WorkItems::SavedViews::SavedView],
          required: true,
          description: 'Global ID of the saved view to unsubscribe from.'

        field :saved_view,
          ::Types::WorkItems::SavedViews::SavedViewType,
          null: true,
          scopes: [:api],
          description: 'Unsubscribed saved view.'

        def resolve(id:)
          saved_view = authorized_find!(id: id)

          unless saved_view.namespace.owner_entity.work_items_saved_views_enabled?(current_user)
            return { saved_view: nil, errors: [_('Saved views are not enabled for this namespace.')] }
          end

          ::WorkItems::SavedViews::UserSavedView.unsubscribe(user: current_user, saved_view: saved_view)

          { saved_view: saved_view }
        end
      end
    end
  end
end
