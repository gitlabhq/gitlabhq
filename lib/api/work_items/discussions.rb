# frozen_string_literal: true

module API
  module WorkItems
    class Discussions < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :portfolio_management
      urgency :low

      helpers ::API::Helpers::WorkItems::Preloads
      helpers ::API::Helpers::WorkItems::Rendering

      SORT_TO_DISCUSSIONS_SORT = {
        'asc' => :created_asc,
        'desc' => :created_desc
      }.freeze

      helpers do
        params :work_item_discussions_params do
          requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
          optional :sort, type: String, values: %w[asc desc], default: 'asc',
            desc: 'Return discussions sorted in `asc` or `desc` creation order.'
          optional :activity_filter, type: String,
            values: UserPreference::NOTES_FILTERS.stringify_keys.keys,
            default: 'all_notes',
            desc: 'Filter discussions by note type. Supported values: all_notes, only_comments, only_activity.'
          optional :cursor, type: String, desc: 'Cursor for keyset pagination.'
          optional :per_page, type: Integer, default: 20, except_values: [0],
            desc: 'Number of discussions to return per page (maximum 100).'
        end

        def render_discussions_endpoint_for(resource_parent)
          parent_work_item = find_work_item_by_iid(resource_parent, params[:work_item_iid])
          not_found!('Work Item') unless parent_work_item

          render_discussions_for(parent_work_item)
        end

        def render_discussions_for(parent_work_item)
          check_work_item_rest_api_feature_flag!
          authorize! :read_work_item, parent_work_item
          authorize! :read_note, parent_work_item

          service = ::Issuable::DiscussionsListService.new(
            current_user, parent_work_item, discussions_list_params
          )

          discussions = service.execute
          paginator = service.paginator

          Gitlab::Pagination::Keyset::HeaderBuilder
            .new(self)
            .add_prev_and_next_cursor_headers(
              paginator.cursor_for_previous_page, paginator.cursor_for_next_page
            )

          present discussions, with: ::API::Entities::Discussion, current_user: current_user
        end

        def discussions_list_params
          {
            notes_filter: UserPreference::NOTES_FILTERS[params[:activity_filter].to_sym],
            sort: SORT_TO_DISCUSSIONS_SORT[params[:sort]],
            cursor: params[:cursor],
            per_page: params[:per_page]
          }
        end
      end

      resource :namespaces do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded full path of the namespace'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List discussions on a work item.' do
            detail 'Get a paginated list of discussions for a work item in a namespace. ' \
              'Project and group namespaces are supported.'
            hidden true
            success ::API::Entities::Discussion
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_discussions_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }],
            job_token_policies: :read_work_items

          get ':work_item_iid/discussions' do
            namespace = find_namespace_by_path!(params[:id].to_s, allow_project_namespaces: true)
            not_found!('Namespace') if namespace.is_a?(::Namespaces::UserNamespace)
            resource_parent = namespace.is_a?(::Namespaces::ProjectNamespace) ? namespace.project : namespace

            render_discussions_endpoint_for(resource_parent)
          end
        end
      end

      resource :projects do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List discussions on a work item in a project.' do
            detail 'Get a paginated list of discussions for a work item in a project.'
            hidden true
            success ::API::Entities::Discussion
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_discussions_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :project,
            job_token_policies: :read_work_items

          get ':work_item_iid/discussions' do
            render_discussions_endpoint_for(find_project!(params[:id]))
          end
        end
      end

      resource :groups do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List discussions on a work item in a group.' do
            detail 'Get a paginated list of discussions for a work item in a group.'
            hidden true
            success ::API::Entities::Discussion
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_discussions_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :group

          get ':work_item_iid/discussions' do
            render_discussions_endpoint_for(find_group!(params[:id]))
          end
        end
      end
    end
  end
end
