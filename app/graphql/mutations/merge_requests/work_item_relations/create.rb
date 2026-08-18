# frozen_string_literal: true

module Mutations
  module MergeRequests
    module WorkItemRelations
      class Create < Base
        graphql_name 'MergeRequestCreateWorkItemRelations'
        description 'Links work items to a merge request.'

        authorize_granular_token permissions: :update_merge_request,
          boundary_argument: :project_path, boundary_type: :project

        argument :work_item_ids, [::Types::GlobalIDType[::WorkItem]],
          required: true,
          description: 'Global IDs of the work items to link.'

        argument :link_type, ::Types::MergeRequests::WorkItemLinkTypeEnum,
          required: false,
          default_value: ::Types::MergeRequests::WorkItemLinkTypeEnum.enum[:related],
          description: 'Type of relationship to create. Defaults to RELATED. ' \
            'MENTIONED relations are managed automatically and cannot be created.'

        field :work_item_relations, [::Types::MergeRequests::WorkItemRelationType],
          null: true,
          description: 'Created merge request to work item relations.'

        def resolve(project_path:, iid:, work_item_ids:, link_type:)
          merge_request = authorized_find!(project_path: project_path, iid: iid)
          raise_resource_not_available_error! unless feature_enabled?(merge_request)

          work_items = ::WorkItem.id_in(work_item_ids.map(&:model_id))

          result = ::MergeRequests::WorkItemRelations::CreateService.new(
            merge_request: merge_request,
            current_user: current_user,
            target_work_items: work_items,
            link_type: link_type
          ).execute

          if result.success?
            { work_item_relations: result.payload[:work_item_relations], errors: Array(result.payload[:errors]) }
          else
            { errors: Array(result.message) }
          end
        end
      end
    end
  end
end
