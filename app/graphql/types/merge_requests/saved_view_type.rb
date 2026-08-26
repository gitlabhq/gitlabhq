# frozen_string_literal: true

module Types
  module MergeRequests
    class SavedViewType < BaseObject
      graphql_name 'MergeRequestSavedView'
      description 'Saved view on the merge request dashboard.'

      authorize :read_saved_view

      authorize_granular_token permissions: :read_saved_view,
        boundary_type: :user

      expose_permissions Types::PermissionTypes::MergeRequests::SavedView

      field :id, Types::GlobalIDType[::MergeRequests::SavedView],
        null: false,
        description: 'Global ID of the saved view.'

      field :name, GraphQL::Types::String,
        null: false,
        description: 'Name of the saved view.'

      field :filters, ::GraphQL::Types::JSON,
        null: false,
        description: 'Merge request filters stored in the saved view.'

      def filters
        object.filters.deep_transform_keys { |key| key.to_s.camelize(:lower) }
      end
    end
  end
end
