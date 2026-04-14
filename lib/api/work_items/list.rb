# frozen_string_literal: true

module API
  module WorkItems
    class List < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :portfolio_management
      urgency :low

      helpers ::API::Helpers::WorkItems::ListParams
      helpers ::API::Helpers::WorkItems::Preloads
      helpers ::API::Helpers::WorkItems::Rendering

      resource :namespaces do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded full path of the namespace'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List work items.' do
            detail 'Get a list of work items in a namespace. Project and group namespaces are supported.'
            hidden true
            success Entities::WorkItemBasic
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            use :work_items_group_list_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }],
            job_token_policies: :read_work_items
          get do
            namespace = find_namespace_by_path!(params[:id].to_s, allow_project_namespaces: true)
            not_found!('Namespace') if namespace.is_a?(::Namespaces::UserNamespace)
            resource_parent = namespace.is_a?(::Namespaces::ProjectNamespace) ? namespace.project : namespace

            render_work_items_collection_for(resource_parent)
          end
        end
      end

      resource :projects do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List work items in a project.' do
            detail 'Get a list of work items in a project.'
            hidden true
            success Entities::WorkItemBasic
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            use :work_items_list_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :project,
            job_token_policies: :read_work_items
          get do
            project = find_project!(params[:id])

            render_work_items_collection_for(project)
          end
        end
      end

      resource :groups do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List work items in a group.' do
            detail 'Get a list of work items in a group.'
            hidden true
            success Entities::WorkItemBasic
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            use :work_items_group_list_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :group
          get do
            group = find_group!(params[:id])

            render_work_items_collection_for(group)
          end
        end
      end
    end
  end
end
