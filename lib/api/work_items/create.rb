# frozen_string_literal: true

module API
  module WorkItems
    class Create < ::API::Base
      before { authenticate! }

      feature_category :portfolio_management
      urgency :low

      helpers ::API::Helpers::WorkItems::CreateParams
      helpers ::API::Helpers::WorkItems::ShowParams
      helpers ::API::Helpers::WorkItems::Creation
      helpers ::API::Helpers::WorkItems::Rendering

      resource :namespaces do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded full path of the namespace'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'Create a work item.' do
            detail 'Create a work item in a namespace. Project and group namespaces are supported.'
            hidden true
            success Entities::WorkItemBasic
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            use :work_items_create_params
            use :work_items_fields_param
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :create_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }]
          post do
            namespace = find_namespace_by_path!(params[:id].to_s, allow_project_namespaces: true)
            not_found!('Namespace') if namespace.is_a?(::Namespaces::UserNamespace)
            resource_parent = namespace.is_a?(::Namespaces::ProjectNamespace) ? namespace.project : namespace

            result = execute_work_item_creation(resource_parent)
            render_work_item_creation(result)
          end
        end
      end

      resource :projects do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'Create a work item in a project.' do
            detail 'Create a work item in a project.'
            hidden true
            success Entities::WorkItemBasic
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            use :work_items_create_params
            use :work_items_fields_param
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :create_work_item,
            boundary_type: :project
          post do
            project = find_project!(params[:id])

            result = execute_work_item_creation(project)
            render_work_item_creation(result)
          end
        end
      end

      resource :groups do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'Create a work item in a group.' do
            detail 'Create a work item in a group.'
            hidden true
            success Entities::WorkItemBasic
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            use :work_items_create_params
            use :work_items_fields_param
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :create_work_item,
            boundary_type: :group
          post do
            group = find_group!(params[:id])

            result = execute_work_item_creation(group)
            render_work_item_creation(result)
          end
        end
      end
    end
  end
end
