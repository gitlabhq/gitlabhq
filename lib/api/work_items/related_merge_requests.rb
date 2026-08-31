# frozen_string_literal: true

module API
  module WorkItems
    class RelatedMergeRequests < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :portfolio_management
      urgency :low

      helpers ::API::Helpers::WorkItems::Authorization
      helpers ::API::Helpers::WorkItems::Preloads
      helpers ::API::Helpers::WorkItems::Rendering

      helpers do
        def render_related_merge_requests_for(parent_work_item)
          authorize_work_item_feature!(parent_work_item)

          project = parent_work_item.project

          # Sourced from the same service as the GraphQL development widget
          # (Resolvers::MergeRequests::WorkItemRelatedResolver) so REST tracks GraphQL instead of
          # reimplementing the derivation. Group-level work items have no project to search.
          related_ids = if project
                          ::Issues::ReferencedMergeRequestsService
                            .new(container: project, current_user: current_user)
                            .related_merge_request_ids(parent_work_item)
                        else
                          []
                        end

          # Re-loaded as a relation so with_api_entity_associations can preload what MergeRequestBasic
          # renders. Querying by id is safe because the service already filtered them through
          # Ability.merge_requests_readable_by_user. Ordered by iid, with id as a tiebreak so
          # pagination stays stable across pages.
          merge_requests = ::MergeRequest.id_in(related_ids)
            .order_iid_asc
            .with_order_id_asc
            .with_api_entity_associations

          present paginate(merge_requests),
            with: ::API::Entities::MergeRequestBasic,
            current_user: current_user,
            project: project,
            skip_merge_status_recheck: true
        end
      end

      resource :namespaces do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded full path of the namespace'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List related merge requests of a work item.' do
            detail 'Get a paginated list of merge requests related to a work item in a namespace. ' \
              'Project and group namespaces are supported.'
            hidden true
            success ::API::Entities::MergeRequestBasic
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
            use :pagination
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }],
            job_token_policies: :read_work_items
          get ':work_item_iid/related_merge_requests' do
            render_related_merge_requests_for(work_item_for_namespace!(params[:id], params[:work_item_iid]))
          end
        end
      end

      resource :projects do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List related merge requests of a work item in a project.' do
            detail 'Get a paginated list of merge requests related to a work item in a project.'
            hidden true
            success ::API::Entities::MergeRequestBasic
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
            use :pagination
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :project,
            job_token_policies: :read_work_items
          get ':work_item_iid/related_merge_requests' do
            render_related_merge_requests_for(work_item_for!(find_project!(params[:id]), params[:work_item_iid]))
          end
        end
      end

      resource :groups do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List related merge requests of a work item in a group.' do
            detail 'Get a paginated list of merge requests related to a work item in a group.'
            hidden true
            success ::API::Entities::MergeRequestBasic
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
            use :pagination
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :group
          get ':work_item_iid/related_merge_requests' do
            render_related_merge_requests_for(work_item_for!(find_group!(params[:id]), params[:work_item_iid]))
          end
        end
      end
    end
  end
end
