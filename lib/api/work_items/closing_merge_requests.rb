# frozen_string_literal: true

module API
  module WorkItems
    class ClosingMergeRequests < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :portfolio_management
      urgency :low

      helpers ::API::Helpers::WorkItems::Authorization
      helpers ::API::Helpers::WorkItems::Preloads
      helpers ::API::Helpers::WorkItems::Rendering

      helpers do
        def render_closing_merge_requests_for(parent_work_item)
          authorize_work_item_feature!(parent_work_item)

          project = parent_work_item.project

          # Closing-issue rows keyed by merge request id, so the entity can expose each row's id and
          # from_mr_description. Bounded: the closing merge requests of a single work item. Group-level
          # work items have no development widget, so this is naturally empty for them.
          closing_rows_by_mr_id = parent_work_item.merge_request_closing_issues.index_by(&:merge_request_id)

          # Not scoped by project: MergeRequestsFinder's project_id filters on target_project_id, which
          # would drop merge requests closing this work item from another project. The finder still
          # filters visibility in SQL, so X-Total counts only readable rows. GraphQL applies the
          # equivalent read_merge_request_closing_issue policy per row.
          merge_requests = ::MergeRequestsFinder
            .new(current_user)
            .execute
            .id_in(closing_rows_by_mr_id.keys)
            .with_api_entity_associations

          present paginate(merge_requests),
            with: ::API::Entities::WorkItems::Features::ClosingMergeRequest,
            current_user: current_user,
            project: project,
            closing_rows_by_mr_id: closing_rows_by_mr_id,
            skip_merge_status_recheck: true
        end
      end

      resource :namespaces do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded full path of the namespace'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List closing merge requests of a work item.' do
            detail 'Get a paginated list of merge requests that close a work item in a namespace. ' \
              'Project and group namespaces are supported.'
            hidden true
            success ::API::Entities::WorkItems::Features::ClosingMergeRequest
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
          get ':work_item_iid/closing_merge_requests' do
            render_closing_merge_requests_for(work_item_for_namespace!(params[:id], params[:work_item_iid]))
          end
        end
      end

      resource :projects do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List closing merge requests of a work item in a project.' do
            detail 'Get a paginated list of merge requests that close a work item in a project.'
            hidden true
            success ::API::Entities::WorkItems::Features::ClosingMergeRequest
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
          get ':work_item_iid/closing_merge_requests' do
            render_closing_merge_requests_for(work_item_for!(find_project!(params[:id]), params[:work_item_iid]))
          end
        end
      end

      resource :groups do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List closing merge requests of a work item in a group.' do
            detail 'Get a paginated list of merge requests that close a work item in a group.'
            hidden true
            success ::API::Entities::WorkItems::Features::ClosingMergeRequest
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
          get ':work_item_iid/closing_merge_requests' do
            render_closing_merge_requests_for(work_item_for!(find_group!(params[:id]), params[:work_item_iid]))
          end
        end
      end
    end
  end
end
