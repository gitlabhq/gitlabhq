# frozen_string_literal: true

module API
  module WorkItems
    class Update < ::API::Base
      before { authenticate! }
      before { check_work_item_rest_api_feature_flag! }

      feature_category :portfolio_management
      urgency :low

      helpers ::API::Helpers::WorkItems::UpdateParams
      helpers ::API::Helpers::WorkItems::ShowParams
      helpers ::API::Helpers::WorkItems::Authorization
      helpers ::API::Helpers::WorkItems::Update
      helpers ::API::Helpers::WorkItems::Rendering
      helpers ::API::Helpers::WorkItems::Preloads
      helpers ::API::Helpers::WorkItems::WidgetValidation

      resource :namespaces do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded full path of the namespace'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'Update a work item.' do
            detail 'Update a work item in a namespace. Project and group namespaces are supported.'
            hidden true
            success Entities::WorkItemBasic
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
            use :work_items_update_params
            use :work_items_fields_param
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }]
          patch ':work_item_iid' do
            work_item = work_item_for_namespace!(params[:id], params[:work_item_iid])

            result = execute_work_item_update(work_item)
            render_work_item_update(result)
          end
        end
      end

      resource :projects do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'Update a work item in a project.' do
            detail 'Update a work item in a project.'
            hidden true
            success Entities::WorkItemBasic
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
            use :work_items_update_params
            use :work_items_fields_param
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_work_item,
            boundary_type: :project
          patch ':work_item_iid' do
            work_item = work_item_for!(find_project!(params[:id]), params[:work_item_iid])

            result = execute_work_item_update(work_item)
            render_work_item_update(result)
          end
        end
      end

      resource :groups do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'Update a work item in a group.' do
            detail 'Update a work item in a group.'
            hidden true
            success Entities::WorkItemBasic
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
            use :work_items_update_params
            use :work_items_fields_param
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_work_item,
            boundary_type: :group
          patch ':work_item_iid' do
            work_item = work_item_for!(find_group!(params[:id]), params[:work_item_iid])

            result = execute_work_item_update(work_item)
            render_work_item_update(result)
          end
        end
      end
    end
  end
end
