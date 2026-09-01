# frozen_string_literal: true

module Mutations
  module MergeRequests
    module SavedViews
      class Create < Base
        graphql_name 'MergeRequestSavedViewCreate'
        description 'Creates a saved view on the merge request dashboard. ' \
          'Available only when the `mr_dashboard_saved_views` feature flag is enabled.'

        authorize :create_saved_view

        authorize_granular_token permissions: :create_saved_view,
          boundary_type: :user

        argument :name, GraphQL::Types::String,
          required: true,
          description: copy_field_description(::Types::MergeRequests::SavedViewType, :name)

        argument :filters, ::Types::MergeRequests::SavedViewFilterInputType,
          required: false,
          description: copy_field_description(::Types::MergeRequests::SavedViewType, :filters)

        def resolve(name:, filters: nil)
          authorize!(current_user)

          result = ::MergeRequests::SavedViews::CreateService.new(
            current_user: current_user,
            params: { name: name, filters: filter_params(filters) }
          ).execute

          saved_view_response(result)
        end
      end
    end
  end
end
