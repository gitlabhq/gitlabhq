# frozen_string_literal: true

module Mutations
  module WorkItems
    module SavedViews
      class Subscribe < BaseMutation
        graphql_name 'WorkItemSavedViewSubscribe'

        authorize :subscribe_work_item_saved_view
        authorize_granular_token permissions: :subscribe_work_item_saved_view,
          boundaries: [
            { boundary_argument: :id, boundary: :resource_parent, boundary_type: :project },
            { boundary_argument: :id, boundary: :resource_parent, boundary_type: :group }
          ]

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
          saved_view = authorized_find!(id: id)

          subscription = ::WorkItems::SavedViews::UserSavedView.subscribe(user: current_user, saved_view: saved_view)

          if subscription
            ::Gitlab::WorkItems::Instrumentation::TrackingService.track_saved_view(
              event: ::Gitlab::WorkItems::Instrumentation::EventActions::SAVED_VIEW_SUBSCRIBE,
              saved_view: saved_view,
              user: current_user
            )
            { saved_view: saved_view, errors: [] }
          else
            { saved_view: nil, errors: [_('Subscribed saved view limit exceeded.')] }
          end
        end
      end
    end
  end
end
