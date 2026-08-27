# frozen_string_literal: true

module API
  module WorkItems
    class RelatedBranches < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :portfolio_management
      urgency :low

      helpers ::API::Helpers::WorkItems::Preloads
      helpers ::API::Helpers::WorkItems::Rendering

      helpers do
        def render_related_branches_for(parent_work_item)
          authorize_work_item_feature!(parent_work_item)

          project = parent_work_item.project

          # Same service as the GraphQL development widget, so REST tracks it rather than
          # reimplementing. Group-level work items have no project to search.
          branches = if project
                       ::Issues::RelatedBranchesService
                         .new(container: project, current_user: current_user)
                         .execute(parent_work_item)
                     else
                       []
                     end

          # Pagination bounds the response, not the work: cost scales with the total matching branch
          # count, not per_page. Sorting by name keeps pages deterministic.
          present paginate(Kaminari.paginate_array(branches.sort_by { |branch| branch[:name] })),
            with: ::API::Entities::WorkItems::Features::RelatedBranch,
            current_user: current_user
        end
      end

      resource :namespaces do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded full path of the namespace'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List related branches of a work item.' do
            detail 'Get a paginated list of branches that reference a work item in a namespace. ' \
              'Project and group namespaces are supported. Group-level work items have no ' \
              'repository to search, so they always return an empty list.'
            hidden true
            success ::API::Entities::WorkItems::Features::RelatedBranch
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
          get ':work_item_iid/related_branches' do
            render_related_branches_for(work_item_for_namespace!(params[:id], params[:work_item_iid]))
          end
        end
      end

      resource :projects do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List related branches of a work item in a project.' do
            detail 'Get a paginated list of branches that reference a work item in a project.'
            hidden true
            success ::API::Entities::WorkItems::Features::RelatedBranch
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
          get ':work_item_iid/related_branches' do
            render_related_branches_for(work_item_for!(find_project!(params[:id]), params[:work_item_iid]))
          end
        end
      end

      resource :groups do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List related branches of a work item in a group.' do
            detail 'Get a paginated list of branches that reference a work item in a group.'
            hidden true
            success ::API::Entities::WorkItems::Features::RelatedBranch
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
          get ':work_item_iid/related_branches' do
            render_related_branches_for(work_item_for!(find_group!(params[:id]), params[:work_item_iid]))
          end
        end
      end
    end
  end
end
