# frozen_string_literal: true

module API
  module WorkItems
    class Notes < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :portfolio_management
      urgency :low

      helpers ::API::Helpers::WorkItems::Preloads
      helpers ::API::Helpers::WorkItems::Rendering

      helpers do
        params :notes_filter_params do
          requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
          optional :order_by, type: String, values: %w[created_at updated_at], default: 'created_at',
            desc: 'Return notes ordered by `created_at` or `updated_at` fields.'
          optional :sort, type: String, values: %w[asc desc], default: 'asc',
            desc: 'Return notes sorted in `asc` or `desc` order.'
          optional :activity_filter, type: String,
            values: UserPreference::NOTES_FILTERS.stringify_keys.keys,
            default: 'all_notes',
            desc: 'Filter notes by type. Supported values: all_notes, only_comments, only_activity.'
          use :pagination
        end

        def render_notes_endpoint_for(resource_parent)
          parent_work_item = find_work_item_by_iid(resource_parent, params[:work_item_iid])
          not_found!('Work Item') unless parent_work_item

          render_notes_for(parent_work_item)
        end

        def render_notes_for(parent_work_item)
          check_work_item_rest_api_feature_flag!
          authorize! :read_work_item, parent_work_item
          authorize! :read_note, parent_work_item

          notes_filter = UserPreference::NOTES_FILTERS[params[:activity_filter].to_sym]
          relation = build_notes_relation(parent_work_item, notes_filter: notes_filter)

          params[:pagination] = 'keyset'
          paginated = paginate_with_strategies(relation)

          visible = paginated.select { |note| note.readable_by?(current_user) }

          present visible, with: ::API::Entities::Note, current_user: current_user
        end
      end

      resource :namespaces do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded full path of the namespace'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List notes on a work item.' do
            detail 'Get a paginated list of notes for a work item in a namespace. ' \
              'Project and group namespaces are supported.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end

          params do
            use :notes_filter_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }],
            job_token_policies: :read_work_items

          get ':work_item_iid/notes' do
            namespace = find_namespace_by_path!(params[:id].to_s, allow_project_namespaces: true)
            not_found!('Namespace') if namespace.is_a?(::Namespaces::UserNamespace)
            resource_parent = namespace.is_a?(::Namespaces::ProjectNamespace) ? namespace.project : namespace

            render_notes_endpoint_for(resource_parent)
          end
        end
      end

      resource :projects do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List notes on a work item in a project.' do
            detail 'Get a paginated list of notes for a work item in a project.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end

          params do
            use :notes_filter_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :project,
            job_token_policies: :read_work_items

          get ':work_item_iid/notes' do
            render_notes_endpoint_for(find_project!(params[:id]))
          end
        end
      end

      resource :groups do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List notes on a work item in a group.' do
            detail 'Get a paginated list of notes for a work item in a group.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end

          params do
            use :notes_filter_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :group

          get ':work_item_iid/notes' do
            render_notes_endpoint_for(find_group!(params[:id]))
          end
        end
      end
    end
  end
end
