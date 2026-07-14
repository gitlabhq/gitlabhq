# frozen_string_literal: true

module API
  module WorkItems
    class CurrentUserTodos < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :portfolio_management
      urgency :low

      helpers ::API::Helpers::WorkItems::Preloads
      helpers ::API::Helpers::WorkItems::Rendering

      helpers do
        def render_current_user_todos_for(parent_work_item)
          check_work_item_rest_api_feature_flag!
          authorize! :read_work_item, parent_work_item

          # TodosFinder treats a nil state as `pending`, so default to both states to mirror the GraphQL widget.
          state = params[:state] || %w[done pending]

          todos = TodosFinder.new(
            users: current_user,
            state: state,
            type: parent_work_item.todoable_target_type_name,
            target_id: parent_work_item.id
          ).execute

          # Preload the associations Entities::Todo serializes per row (target, author, note, project, group)
          # to avoid N+1 queries proportional to per_page, matching the canonical /todos endpoint.
          present paginate(todos.with_entity_associations), with: ::API::Entities::Todo, current_user: current_user
        end
      end

      resource :namespaces do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded full path of the namespace'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List current user to-do items on a work item.' do
            detail 'Get a paginated list of the current user to-do items for a work item in a namespace. ' \
              'Project and group namespaces are supported.'
            hidden true
            success ::API::Entities::Todo
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
            optional :state, type: String, values: %w[pending done],
              desc: 'Return to-do items with the given state. Returns both states when omitted.'
            use :pagination
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }],
            job_token_policies: :read_work_items
          get ':work_item_iid/current_user_todos' do
            namespace = find_namespace_by_path!(params[:id].to_s, allow_project_namespaces: true)
            not_found!('Namespace') if namespace.is_a?(::Namespaces::UserNamespace)
            resource_parent = namespace.is_a?(::Namespaces::ProjectNamespace) ? namespace.project : namespace

            parent_work_item = find_work_item_by_iid(resource_parent, params[:work_item_iid])
            not_found!('Work Item') unless parent_work_item

            render_current_user_todos_for(parent_work_item)
          end
        end
      end

      resource :projects do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List current user to-do items on a work item in a project.' do
            detail 'Get a paginated list of the current user to-do items for a work item in a project.'
            hidden true
            success ::API::Entities::Todo
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
            optional :state, type: String, values: %w[pending done],
              desc: 'Return to-do items with the given state. Returns both states when omitted.'
            use :pagination
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :project,
            job_token_policies: :read_work_items
          get ':work_item_iid/current_user_todos' do
            project = find_project!(params[:id])

            parent_work_item = find_work_item_by_iid(project, params[:work_item_iid])
            not_found!('Work Item') unless parent_work_item

            render_current_user_todos_for(parent_work_item)
          end
        end
      end

      resource :groups do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List current user to-do items on a work item in a group.' do
            detail 'Get a paginated list of the current user to-do items for a work item in a group.'
            hidden true
            success ::API::Entities::Todo
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
            optional :state, type: String, values: %w[pending done],
              desc: 'Return to-do items with the given state. Returns both states when omitted.'
            use :pagination
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :group
          get ':work_item_iid/current_user_todos' do
            group = find_group!(params[:id])

            parent_work_item = find_work_item_by_iid(group, params[:work_item_iid])
            not_found!('Work Item') unless parent_work_item

            render_current_user_todos_for(parent_work_item)
          end
        end
      end
    end
  end
end
