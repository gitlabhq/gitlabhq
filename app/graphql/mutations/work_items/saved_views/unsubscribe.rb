# frozen_string_literal: true

module Mutations
  module WorkItems
    module SavedViews
      class Unsubscribe < BaseMutation
        graphql_name 'WorkItemSavedViewUnsubscribe'

        authorize :unsubscribe_work_item_saved_view
        authorize_granular_token permissions: :unsubscribe_work_item_saved_view,
          boundaries: [
            { boundary_argument: :id, boundary: :resource_parent, boundary_type: :project },
            { boundary_argument: :id, boundary: :resource_parent, boundary_type: :group }
          ]

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

          unsubscribed = ::WorkItems::SavedViews::UserSavedView.unsubscribe(user: current_user, saved_view: saved_view)

          if unsubscribed
            ::Gitlab::WorkItems::Instrumentation::TrackingService.track_saved_view(
              event: ::Gitlab::WorkItems::Instrumentation::EventActions::SAVED_VIEW_UNSUBSCRIBE,
              saved_view: saved_view,
              user: current_user
            )
          end

          { saved_view: saved_view, errors: [] }
        end
      end
    end
  end
end
