# frozen_string_literal: true

module API
  module WorkItems
    class LinkedItems < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :portfolio_management
      urgency :low

      helpers ::API::Helpers::WorkItems::ShowParams
      helpers ::API::Helpers::WorkItems::Preloads
      helpers ::API::Helpers::WorkItems::Rendering

      helpers do
        params :linked_items_filter_params do
          requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
          use :work_items_show_params
          optional :state, type: String, values: %w[opened closed],
            desc: 'Filter linked items by state. Supported values: opened, closed.'
          optional :link_type, type: String, values: ::WorkItems::RelatedWorkItemLink.available_link_types,
            desc: 'Filter by link type. Returns all link types if omitted.'
          use :pagination
        end
      end

      resource :namespaces do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded full path of the namespace'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List linked items of a work item.' do
            detail 'Get a paginated list of items linked to a work item in a namespace. ' \
              'Project and group namespaces are supported.'
            hidden true
            success ::API::Entities::WorkItems::LinkedWorkItem
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            use :linked_items_filter_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }],
            job_token_policies: :read_work_items
          get ':work_item_iid/linked_items' do
            namespace = find_namespace_by_path!(params[:id].to_s, allow_project_namespaces: true)
            not_found!('Namespace') if namespace.is_a?(::Namespaces::UserNamespace)
            resource_parent = namespace.is_a?(::Namespaces::ProjectNamespace) ? namespace.project : namespace

            parent_work_item = find_work_item_by_iid(resource_parent, params[:work_item_iid])
            not_found!('Work Item') unless parent_work_item

            render_linked_items_for(parent_work_item, link_type: params[:link_type])
          end
        end
      end

      resource :projects do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List linked items of a work item in a project.' do
            detail 'Get a paginated list of items linked to a work item in a project.'
            hidden true
            success ::API::Entities::WorkItems::LinkedWorkItem
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            use :linked_items_filter_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :project,
            job_token_policies: :read_work_items
          get ':work_item_iid/linked_items' do
            project = find_project!(params[:id])

            parent_work_item = find_work_item_by_iid(project, params[:work_item_iid])
            not_found!('Work Item') unless parent_work_item

            render_linked_items_for(parent_work_item, link_type: params[:link_type])
          end
        end
      end

      resource :groups do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List linked items of a work item in a group.' do
            detail 'Get a paginated list of items linked to a work item in a group.'
            hidden true
            success ::API::Entities::WorkItems::LinkedWorkItem
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            use :linked_items_filter_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :group
          get ':work_item_iid/linked_items' do
            group = find_group!(params[:id])

            parent_work_item = find_work_item_by_iid(group, params[:work_item_iid])
            not_found!('Work Item') unless parent_work_item

            render_linked_items_for(parent_work_item, link_type: params[:link_type])
          end
        end
      end
    end
  end
end
