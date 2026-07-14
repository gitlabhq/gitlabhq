# frozen_string_literal: true

module Mutations
  module MergeRequests
    module WorkItemRelations
      class Destroy < Base
        graphql_name 'MergeRequestDestroyWorkItemRelations'
        description 'Removes relations between a merge request and work items.'

        authorize_granular_token permissions: :update_merge_request,
          boundary_argument: :project_path, boundary_type: :project

        argument :ids, [::Types::GlobalIDType[::MergeRequestsClosingIssues]],
          required: true,
          description: 'Global IDs of the relations to remove.'

        field :removed_relation_ids, [::Types::GlobalIDType[::MergeRequestsClosingIssues]],
          null: true,
          description: 'Global IDs of the removed relations.'

        def resolve(project_path:, iid:, ids:)
          merge_request = authorized_find!(project_path: project_path, iid: iid)
          raise_resource_not_available_error! unless feature_enabled?(merge_request)

          result = ::MergeRequests::WorkItemRelations::DestroyService.new(
            merge_request: merge_request,
            current_user: current_user,
            ids: ids.map(&:model_id)
          ).execute

          if result.success?
            removed = result.payload[:removed_ids].to_set(&:to_s)
            { removed_relation_ids: ids.select { |gid| removed.include?(gid.model_id.to_s) }, errors: [] }
          else
            { errors: Array(result.message) }
          end
        end
      end
    end
  end
end
