# frozen_string_literal: true

module API
  module WorkItems
    class Notes < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :portfolio_management
      urgency :low

      helpers ::API::Helpers::WorkItems::Authorization
      helpers ::API::Helpers::WorkItems::Preloads
      helpers ::API::Helpers::WorkItems::Rendering
      helpers ::API::Helpers::NotesHelpers

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

        params :work_item_note_params do
          requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
          requires :note_id, type: Integer, desc: 'The ID of a note'
        end

        def render_note_for(parent_work_item)
          authorize_work_item_feature!(parent_work_item)
          authorize! :read_note, parent_work_item

          # Scoped to the work item's own notes, so a note id belonging to another noteable 404s.
          # Deliberately not NotesHelpers#get_note: its EE override presents epics with the legacy
          # LegacyEpicNote entity, whereas this API renders every scope with Entities::Note.
          note = parent_work_item.notes
            .preload(::API::Helpers::WorkItems::Preloads::NOTE_REFERENCE_PRELOADS) # rubocop:disable CodeReuse/ActiveRecord -- Preloading associations for API response
            .find_by_id(params[:note_id])
          not_found!('Note') unless note&.readable_by?(current_user)

          present note, with: ::API::Entities::Note, current_user: current_user
        end

        params :note_create_params do
          requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
          requires :body, type: String, desc: 'The content of a note'
          optional :internal, type: Boolean, desc: 'Internal note flag, default is false'
          optional :created_at, type: String, desc: 'The creation date of the note'
        end

        def create_note_for(parent_work_item)
          authorize_work_item_feature!(parent_work_item)
          authorize! :create_note, parent_work_item

          allowlist = Gitlab::CurrentSettings.current_application_settings.notes_create_limit_allowlist
          check_rate_limit! :notes_create, scope: current_user, users_allowlist: allowlist

          opts = {
            noteable: parent_work_item,
            note: params[:body],
            internal: params[:internal],
            created_at: params[:created_at],
            scope_validator: ::Gitlab::Auth::ScopeValidator.new(
              current_user, Gitlab::Auth::RequestAuthenticator.new(request)
            )
          }
          opts.delete(:created_at) unless current_user.can?(:set_note_created_at, parent_work_item)
          opts[:updated_at] = opts[:created_at] if opts[:created_at]

          disable_query_limiting

          # Group-level work items have no project; the service accepts nil, as the legacy epic notes path does.
          note = ::Notes::CreateService.new(parent_work_item.project, current_user, opts).execute

          process_note_creation_result(note) do
            present note, with: ::API::Entities::Note, current_user: current_user
          end
        rescue QuickActions::InterpretService::QuickActionsNotAllowedError => e
          forbidden!(e.message)
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

          desc 'Get a note on a work item.' do
            detail 'Get a single note for a work item in a namespace. Project and group namespaces are supported.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_note_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }]

          get ':work_item_iid/notes/:note_id' do
            render_note_for(work_item_for_namespace!(params[:id], params[:work_item_iid]))
          end

          desc 'Create a note on a work item.' do
            detail 'Create a new note on a work item in a namespace. Project and group namespaces are supported.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :note_create_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :create_note,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }]

          post ':work_item_iid/notes' do
            create_note_for(work_item_for_namespace!(params[:id], params[:work_item_iid]))
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

          desc 'Get a note on a work item.' do
            detail 'Get a single note for a work item in a project.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_note_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :project

          get ':work_item_iid/notes/:note_id' do
            render_note_for(work_item_for!(find_project!(params[:id]), params[:work_item_iid]))
          end

          desc 'Create a note on a work item in a project.' do
            detail 'Create a new note on a work item in a project.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :note_create_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :create_note,
            boundary_type: :project

          post ':work_item_iid/notes' do
            create_note_for(work_item_for!(find_project!(params[:id]), params[:work_item_iid]))
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

          desc 'Get a note on a work item.' do
            detail 'Get a single note for a work item in a group.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_note_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :group

          get ':work_item_iid/notes/:note_id' do
            render_note_for(work_item_for!(find_group!(params[:id]), params[:work_item_iid]))
          end

          desc 'Create a note on a work item in a group.' do
            detail 'Create a new note on a work item in a group.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :note_create_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :create_note,
            boundary_type: :group

          post ':work_item_iid/notes' do
            create_note_for(work_item_for!(find_group!(params[:id]), params[:work_item_iid]))
          end
        end
      end
    end
  end
end
