# frozen_string_literal: true

module Mutations
  module MergeRequests
    module SavedViews
      class Update < Base
        graphql_name 'MergeRequestSavedViewUpdate'
        description 'Updates a saved view on the merge request dashboard. ' \
          'Available only when the `mr_dashboard_saved_views` feature flag is enabled.'

        authorize :update_saved_view

        authorize_granular_token permissions: :update_saved_view,
          boundary_type: :user

        argument :id, ::Types::GlobalIDType[::MergeRequests::SavedView],
          required: true,
          description: copy_field_description(::Types::MergeRequests::SavedViewType, :id)

        argument :filters, ::Types::MergeRequests::SavedViewFilterInputType,
          required: false,
          description: copy_field_description(::Types::MergeRequests::SavedViewType, :filters)
        argument :name, GraphQL::Types::String,
          required: false,
          description: copy_field_description(::Types::MergeRequests::SavedViewType, :name)

        def resolve(id:, **attrs)
          saved_view = authorized_find!(id: id)

          attrs[:filters] = filter_params(attrs[:filters]) if attrs.key?(:filters)

          result = ::MergeRequests::SavedViews::UpdateService.new(
            saved_view,
            current_user: current_user,
            params: attrs
          ).execute

          saved_view_response(result)
        end
      end
    end
  end
end
