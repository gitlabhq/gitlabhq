# frozen_string_literal: true

module API
  module WorkItems
    class LinkedResources < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :portfolio_management
      urgency :low

      helpers ::API::Helpers::WorkItems::Preloads
      helpers ::API::Helpers::WorkItems::Rendering

      helpers do
        def render_linked_resources_for(parent_work_item)
          check_work_item_rest_api_feature_flag!
          authorize! :read_work_item, parent_work_item

          widget = parent_work_item.get_widget(:linked_resources)
          resources = widget ? widget.zoom_meetings : ZoomMeeting.none

          present paginate(resources), with: ::API::Entities::WorkItems::LinkedResource
        end
      end

      resource :namespaces do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded full path of the namespace'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List linked resources of a work item.' do
            detail 'Get a paginated list of resources linked to a work item in a namespace. ' \
              'Project and group namespaces are supported.'
            hidden true
            success ::API::Entities::WorkItems::LinkedResource
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
          get ':work_item_iid/linked_resources' do
            namespace = find_namespace_by_path!(params[:id].to_s, allow_project_namespaces: true)
            not_found!('Namespace') if namespace.is_a?(::Namespaces::UserNamespace)
            resource_parent = namespace.is_a?(::Namespaces::ProjectNamespace) ? namespace.project : namespace

            parent_work_item = find_work_item_by_iid(resource_parent, params[:work_item_iid])
            not_found!('Work Item') unless parent_work_item

            render_linked_resources_for(parent_work_item)
          end
        end
      end

      resource :projects do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List linked resources of a work item in a project.' do
            detail 'Get a paginated list of resources linked to a work item in a project.'
            hidden true
            success ::API::Entities::WorkItems::LinkedResource
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
          get ':work_item_iid/linked_resources' do
            project = find_project!(params[:id])

            parent_work_item = find_work_item_by_iid(project, params[:work_item_iid])
            not_found!('Work Item') unless parent_work_item

            render_linked_resources_for(parent_work_item)
          end
        end
      end

      resource :groups do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List linked resources of a work item in a group.' do
            detail 'Get a paginated list of resources linked to a work item in a group.'
            hidden true
            success ::API::Entities::WorkItems::LinkedResource
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
          get ':work_item_iid/linked_resources' do
            group = find_group!(params[:id])

            parent_work_item = find_work_item_by_iid(group, params[:work_item_iid])
            not_found!('Work Item') unless parent_work_item

            render_linked_resources_for(parent_work_item)
          end
        end
      end
    end
  end
end
