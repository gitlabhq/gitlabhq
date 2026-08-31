# frozen_string_literal: true

module API
  module WorkItems
    class Children < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :portfolio_management
      urgency :low

      helpers ::API::Helpers::WorkItems::ShowParams
      helpers ::API::Helpers::WorkItems::Authorization
      helpers ::API::Helpers::WorkItems::Preloads
      helpers ::API::Helpers::WorkItems::Rendering
      helpers ::API::Helpers::WorkItems::HierarchyActions
      helpers ::API::Helpers::WorkItems::HierarchyFinders

      ATTACH_CHILD_FAILURE_RESPONSES = (FAILURE_RESPONSES + [
        { code: 409, message: 'Conflict - the work item is already a child of this parent' },
        { code: 422, message: 'Unprocessable entity - the hierarchy is not valid' }
      ]).freeze

      DETACH_CHILD_FAILURE_RESPONSES = (FAILURE_RESPONSES + [
        { code: 422, message: 'Unprocessable entity - the child could not be detached' }
      ]).freeze

      REORDER_CHILD_FAILURE_RESPONSES = (FAILURE_RESPONSES + [
        { code: 422, message: 'Unprocessable entity - the child could not be reordered' }
      ]).freeze

      helpers do
        params :list_children_params do
          requires :work_item_iid, type: Integer, desc: 'The internal ID of the parent work item'
          use :work_items_show_params
          optional :state, type: String, values: %w[opened closed],
            desc: 'Filter children by state. Supported values: opened, closed.'
          use :pagination
        end

        params :attach_child_params do
          requires :work_item_iid, type: Integer, desc: 'The internal ID of the parent work item'
          requires :child_id, type: Integer,
            desc: 'The ID of the work item to attach as a child. ' \
              'The internal ID (iid) cannot be used because the child ' \
              'can belong to a different namespace than the parent.'
        end

        params :detach_child_params do
          requires :work_item_iid, type: Integer, desc: 'The internal ID of the parent work item'
          requires :child_id, type: Integer,
            desc: 'The ID of the child work item to detach from the parent. ' \
              'The internal ID (iid) cannot be used because the child ' \
              'can belong to a different namespace than the parent.'
        end

        params :reorder_child_params do
          requires :work_item_iid, type: Integer, desc: 'The internal ID of the parent work item'
          requires :child_id, type: Integer,
            desc: 'The ID of the child work item to reorder. ' \
              'The internal ID (iid) cannot be used because the child ' \
              'can belong to a different namespace than the parent.'
          optional :move_before_id, type: Integer,
            desc: 'The ID (not iid) of the sibling work item that should be positioned before the child work item.'
          optional :move_after_id, type: Integer,
            desc: 'The ID (not iid) of the sibling work item that should be positioned after the child work item.'
          at_least_one_of :move_before_id, :move_after_id
        end
      end

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
            use :list_children_params
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
            use :attach_child_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }]
          post ':work_item_iid/children/:child_id' do
            resource_parent = resolve_namespace_resource_parent!(params[:id])

            attach_child_work_item!(resource_parent, params[:work_item_iid], params[:child_id])
          end

          desc 'Detach a child work item.' do
            detail 'Remove a work item as a child of a work item in a namespace. ' \
              'Project and group namespaces are supported.'
            hidden true
            success code: 204
            failure DETACH_CHILD_FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            use :detach_child_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }]
          delete ':work_item_iid/children/:child_id' do
            resource_parent = resolve_namespace_resource_parent!(params[:id])

            detach_child_work_item!(resource_parent, params[:work_item_iid], params[:child_id])
          end

          desc 'Reorder a child work item.' do
            detail 'Reorder a child work item within its parent\'s list of children in a namespace. ' \
              'Project and group namespaces are supported.'
            hidden true
            success Entities::WorkItemBasic
            failure REORDER_CHILD_FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            use :reorder_child_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }]
          put ':work_item_iid/children/:child_id' do
            resource_parent = resolve_namespace_resource_parent!(params[:id])

            reorder_child_work_item!(
              resource_parent: resource_parent,
              work_item_iid: params[:work_item_iid],
              child_id: params[:child_id],
              move_before_id: params[:move_before_id],
              move_after_id: params[:move_after_id]
            )
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
            use :list_children_params
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
            use :attach_child_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_work_item,
            boundary_type: :project
          post ':work_item_iid/children/:child_id' do
            project = find_project!(params[:id])

            attach_child_work_item!(project, params[:work_item_iid], params[:child_id])
          end

          desc 'Detach a child work item from a work item in a project.' do
            detail 'Remove a work item as a child of a work item in a project.'
            hidden true
            success code: 204
            failure DETACH_CHILD_FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            use :detach_child_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_work_item,
            boundary_type: :project
          delete ':work_item_iid/children/:child_id' do
            project = find_project!(params[:id])

            detach_child_work_item!(project, params[:work_item_iid], params[:child_id])
          end

          desc 'Reorder a child work item in a project.' do
            detail 'Reorder a child work item within its parent\'s list of children in a project.'
            hidden true
            success Entities::WorkItemBasic
            failure REORDER_CHILD_FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            use :reorder_child_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_work_item,
            boundary_type: :project
          put ':work_item_iid/children/:child_id' do
            project = find_project!(params[:id])

            reorder_child_work_item!(
              resource_parent: project,
              work_item_iid: params[:work_item_iid],
              child_id: params[:child_id],
              move_before_id: params[:move_before_id],
              move_after_id: params[:move_after_id]
            )
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
            use :list_children_params
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
            use :attach_child_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_work_item,
            boundary_type: :group
          post ':work_item_iid/children/:child_id' do
            group = find_group!(params[:id])

            attach_child_work_item!(group, params[:work_item_iid], params[:child_id])
          end

          desc 'Detach a child work item from a work item in a group.' do
            detail 'Remove a work item as a child of a work item in a group.'
            hidden true
            success code: 204
            failure DETACH_CHILD_FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            use :detach_child_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_work_item,
            boundary_type: :group
          delete ':work_item_iid/children/:child_id' do
            group = find_group!(params[:id])

            detach_child_work_item!(group, params[:work_item_iid], params[:child_id])
          end

          desc 'Reorder a child work item in a group.' do
            detail 'Reorder a child work item within its parent\'s list of children in a group.'
            hidden true
            success Entities::WorkItemBasic
            failure REORDER_CHILD_FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            use :reorder_child_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_work_item,
            boundary_type: :group
          put ':work_item_iid/children/:child_id' do
            group = find_group!(params[:id])

            reorder_child_work_item!(
              resource_parent: group,
              work_item_iid: params[:work_item_iid],
              child_id: params[:child_id],
              move_before_id: params[:move_before_id],
              move_after_id: params[:move_after_id]
            )
          end
        end
      end
    end
  end
end
