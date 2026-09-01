# frozen_string_literal: true

module Mutations
  module MergeRequests
    module SavedViews
      class Delete < Base
        graphql_name 'MergeRequestSavedViewDelete'
        description 'Deletes a saved view from the merge request dashboard. ' \
          'Available only when the `mr_dashboard_saved_views` feature flag is enabled.'

        authorize :delete_saved_view

        authorize_granular_token permissions: :delete_saved_view,
          boundary_type: :user

        argument :id, ::Types::GlobalIDType[::MergeRequests::SavedView],
          required: true,
          description: copy_field_description(::Types::MergeRequests::SavedViewType, :id)

        def resolve(id:)
          saved_view = authorized_find!(id: id)

          result = ::MergeRequests::SavedViews::DeleteService.new(saved_view, current_user: current_user).execute

          saved_view_response(result)
        end
      end
    end
  end
end
