# frozen_string_literal: true

module API
  module WorkItems
    class Show < ::API::Base
      include ::API::Concerns::AiWorkflowsAccess
      include APIGuard

      allow_ai_workflows_access

      before { authenticate! }

      feature_category :portfolio_management
      urgency :low

      helpers ::API::Helpers::WorkItems::ShowParams
      helpers ::API::Helpers::WorkItems::Preloads
      helpers ::API::Helpers::WorkItems::Rendering

      resource :namespaces do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded full path of the namespace'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'Get a work item.' do
            detail 'Get a single work item in a namespace. Project and group namespaces are supported.'
            hidden true
            success Entities::WorkItemBasic
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
            use :work_items_show_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }],
            job_token_policies: :read_work_items
          get ':work_item_iid' do
            namespace = find_namespace_by_path!(params[:id].to_s, allow_project_namespaces: true)
            not_found!('Namespace') if namespace.is_a?(::Namespaces::UserNamespace)
            resource_parent = namespace.is_a?(::Namespaces::ProjectNamespace) ? namespace.project : namespace

            render_work_item_for(resource_parent, params[:work_item_iid])
          end
        end
      end

      resource :projects do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'Get a work item in a project.' do
            detail 'Get a single work item in a project.'
            hidden true
            success Entities::WorkItemBasic
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
            use :work_items_show_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :project,
            job_token_policies: :read_work_items
          get ':work_item_iid' do
            project = find_project!(params[:id])

            render_work_item_for(project, params[:work_item_iid])
          end
        end
      end

      resource :groups do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'Get a work item in a group.' do
            detail 'Get a single work item in a group.'
            hidden true
            success Entities::WorkItemBasic
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
            use :work_items_show_params
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :group
          get ':work_item_iid' do
            group = find_group!(params[:id])

            render_work_item_for(group, params[:work_item_iid])
          end
        end
      end
    end
  end
end
