# frozen_string_literal: true

module Resolvers
  module WorkItems
    module SavedViews
      class SavedViewsResolver < BaseResolver
        argument :id,
          ::Types::GlobalIDType[::WorkItems::SavedViews::SavedView],
          required: false,
          description: 'ID of the saved view.'

        argument :search,
          GraphQL::Types::String,
          required: false,
          description: 'Search query for saved view name or description.'

        argument :subscribed_only,
          GraphQL::Types::Boolean,
          required: false,
          description: 'Whether to return only saved views subscribed to by the current user.'

        argument :sort,
          Types::WorkItems::SavedViews::SortEnum,
          description: 'Sort work items by criteria. Default is ID.',
          required: false,
          default_value: :id

        type Types::WorkItems::SavedViews::SavedViewType.connection_type, null: true

        def resolve(**_args)
          ::WorkItems::SavedViews::SavedView.none
        end
      end
    end
  end
end
