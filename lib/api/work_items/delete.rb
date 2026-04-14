# frozen_string_literal: true

module API
  module WorkItems
    class Delete < ::API::Base
      before { authenticate! }

      feature_category :portfolio_management
      urgency :low

      helpers ::API::Helpers::WorkItems::Preloads

      helpers do
        def delete_work_item(resource_parent)
          forbidden!('work_item_rest_api feature flag is disabled for this user') unless
            Feature.enabled?(:work_item_rest_api, current_user)

          work_item = build_work_items_relation(resource_parent).without_order.find_by_iid(params[:work_item_iid])
          not_found!('Work Item') unless work_item

          authorize! :delete_work_item, work_item

          result = ::WorkItems::DeleteService.new(
            container: resource_parent,
            current_user: current_user
          ).execute(work_item)

          if result.success?
            status :no_content
          else
            render_api_error!(Array(result.message).join(', '), result.http_status || :unprocessable_entity)
          end
        end
      end

      resource :namespaces do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded full path of the namespace'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'Delete a work item.' do
            detail 'Delete a work item in a namespace. Project and group namespaces are supported.'
            hidden true
            success code: 204
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :delete_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }]
          delete ':work_item_iid' do
            namespace = find_namespace_by_path!(params[:id].to_s, allow_project_namespaces: true)
            not_found!('Namespace') if namespace.is_a?(::Namespaces::UserNamespace)
            resource_parent = namespace.is_a?(::Namespaces::ProjectNamespace) ? namespace.project : namespace

            delete_work_item(resource_parent)
          end
        end
      end

      resource :projects do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'Delete a work item in a project.' do
            detail 'Delete a work item in a project.'
            hidden true
            success code: 204
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :delete_work_item,
            boundary_type: :project
          delete ':work_item_iid' do
            delete_work_item(find_project!(params[:id]))
          end
        end
      end

      resource :groups do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'Delete a work item in a group.' do
            detail 'Delete a work item in a group.'
            hidden true
            success code: 204
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :delete_work_item,
            boundary_type: :group
          delete ':work_item_iid' do
            delete_work_item(find_group!(params[:id]))
          end
        end
      end
    end
  end
end
