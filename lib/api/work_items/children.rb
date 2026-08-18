# frozen_string_literal: true

module API
  module WorkItems
    class Children < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :portfolio_management
      urgency :low

      helpers ::API::Helpers::WorkItems::ShowParams
      helpers ::API::Helpers::WorkItems::Preloads
      helpers ::API::Helpers::WorkItems::Rendering
      helpers ::API::Helpers::WorkItems::HierarchyActions
      helpers ::API::Helpers::WorkItems::HierarchyFinders

      ATTACH_CHILD_FAILURE_RESPONSES = (FAILURE_RESPONSES + [
        { code: 409, message: 'Conflict - the work item is already a child of this parent' },
        { code: 422, message: 'Unprocessable entity - the hierarchy is not valid' }
      ]).freeze

      resource :namespaces do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded full path of the namespace'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List children of a work item.' do
            detail 'Get a paginated list of children for a work item in a namespace. ' \
              'Project and group namespaces are supported.'
            hidden true
            success Entities::WorkItemBasic
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the parent work item'
            use :work_items_show_params
            optional :state, type: String, values: %w[opened closed],
              desc: 'Filter children by state. Supported values: opened, closed.'
            use :pagination
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }],
            job_token_policies: :read_work_items
          get ':work_item_iid/children' do
            resource_parent = resolve_namespace_resource_parent!(params[:id])

            parent_work_item = find_parent_work_item!(resource_parent, params[:work_item_iid])
            render_children_for(parent_work_item)
          end

          desc 'Attach a child work item.' do
            detail 'Attach an existing work item as a child of a work item in a namespace. ' \
              'Project and group namespaces are supported.'
            hidden true
            success Entities::WorkItemBasic
            failure ATTACH_CHILD_FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the parent work item'
            requires :child_id, type: Integer,
              desc: 'The ID of the work item to attach as a child. ' \
                'The internal ID (iid) cannot be used because the child ' \
                'can belong to a different namespace than the parent.'
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }]
          post ':work_item_iid/children/:child_id' do
            resource_parent = resolve_namespace_resource_parent!(params[:id])

            attach_child_work_item!(resource_parent, params[:work_item_iid], params[:child_id])
          end
        end
      end

      resource :projects do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List children of a work item in a project.' do
            detail 'Get a paginated list of children for a work item in a project.'
            hidden true
            success Entities::WorkItemBasic
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the parent work item'
            use :work_items_show_params
            optional :state, type: String, values: %w[opened closed],
              desc: 'Filter children by state. Supported values: opened, closed.'
            use :pagination
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :project,
            job_token_policies: :read_work_items
          get ':work_item_iid/children' do
            project = find_project!(params[:id])

            parent_work_item = find_parent_work_item!(project, params[:work_item_iid])
            render_children_for(parent_work_item)
          end

          desc 'Attach a child work item to a work item in a project.' do
            detail 'Attach an existing work item as a child of a work item in a project.'
            hidden true
            success Entities::WorkItemBasic
            failure ATTACH_CHILD_FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the parent work item'
            requires :child_id, type: Integer,
              desc: 'The ID of the work item to attach as a child. ' \
                'The internal ID (iid) cannot be used because the child ' \
                'can belong to a different namespace than the parent.'
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_work_item,
            boundary_type: :project
          post ':work_item_iid/children/:child_id' do
            project = find_project!(params[:id])

            attach_child_work_item!(project, params[:work_item_iid], params[:child_id])
          end
        end
      end

      resource :groups do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List children of a work item in a group.' do
            detail 'Get a paginated list of children for a work item in a group.'
            hidden true
            success Entities::WorkItemBasic
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the parent work item'
            use :work_items_show_params
            optional :state, type: String, values: %w[opened closed],
              desc: 'Filter children by state. Supported values: opened, closed.'
            use :pagination
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :group
          get ':work_item_iid/children' do
            group = find_group!(params[:id])

            parent_work_item = find_parent_work_item!(group, params[:work_item_iid])
            render_children_for(parent_work_item)
          end

          desc 'Attach a child work item to a work item in a group.' do
            detail 'Attach an existing work item as a child of a work item in a group.'
            hidden true
            success Entities::WorkItemBasic
            failure ATTACH_CHILD_FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the parent work item'
            requires :child_id, type: Integer,
              desc: 'The ID of the work item to attach as a child. ' \
                'The internal ID (iid) cannot be used because the child ' \
                'can belong to a different namespace than the parent.'
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_work_item,
            boundary_type: :group
          post ':work_item_iid/children/:child_id' do
            group = find_group!(params[:id])

            attach_child_work_item!(group, params[:work_item_iid], params[:child_id])
          end
        end
      end
    end
  end
end
