# frozen_string_literal: true

module API
  module WorkItems
    class DiscussionNotes < ::API::Base
      before { authenticate! }
      before { check_work_item_rest_api_feature_flag! }

      feature_category :portfolio_management
      urgency :low

      DELETE_FAILURE_RESPONSES = (FAILURE_RESPONSES + [{ code: 412, message: 'Precondition failed' }]).freeze

      helpers ::API::Helpers::WorkItems::Authorization
      helpers ::API::Helpers::WorkItems::Preloads
      helpers ::API::Helpers::NotesHelpers
      helpers ::API::Helpers::WorkItems::NoteCreation

      helpers do
        def no_readable_notes_in_discussion?(parent_work_item)
          readable_discussion_notes(parent_work_item, params[:discussion_id]).empty?
        end

        params :work_item_discussion_params do
          requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
          requires :discussion_id, type: String, desc: 'The ID of a discussion'
        end

        params :work_item_discussion_notes_params do
          use :work_item_discussion_params
          optional :cursor, type: String, desc: 'Cursor for keyset pagination.'
          optional :per_page, type: Integer, default: 20, values: 1..100,
            desc: 'Number of notes to return per page (maximum 100).'
        end

        params :work_item_discussion_note_params do
          use :work_item_discussion_params
          requires :note_id, type: Integer, desc: 'The ID of a note'
        end

        params :work_item_update_discussion_note_params do
          use :work_item_discussion_note_params
          optional :body, type: String, desc: 'The content of a note'
          optional :resolved, type: Boolean, desc: 'Mark note resolved/unresolved', allow_blank: false
          exactly_one_of :body, :resolved
        end

        def render_discussion_notes_for(parent_work_item)
          authorize_work_item_feature!(parent_work_item)
          authorize! :read_note, parent_work_item

          paginator = build_discussion_notes_relation(parent_work_item, params[:discussion_id])
            .keyset_paginate(cursor: params[:cursor], per_page: params[:per_page])

          notes = paginator.records.select { |note| note.readable_by?(current_user) }
          # An empty page can be a cursor past the end or only unreadable notes, so fall back to checking the thread.
          not_found!('Discussion') if notes.empty? && no_readable_notes_in_discussion?(parent_work_item)

          # Cursors come from the unfiltered page so paging never skips notes hidden between readable ones.
          if paginator.records.any?
            Gitlab::Pagination::Keyset::HeaderBuilder
              .new(self)
              .add_prev_and_next_cursor_headers(
                paginator.cursor_for_previous_page, paginator.cursor_for_next_page
              )
          end

          present notes, with: ::API::Entities::Note, current_user: current_user
        end

        params :work_item_discussion_reply_params do
          use :work_item_discussion_params
          requires :body, type: String, desc: 'The content of a note'
          optional :created_at, type: String, desc: 'The creation date of the note'
        end

        def reply_to_discussion_for(parent_work_item)
          # Authorize and rate limit before the lookup so non-members get 403 rather than a 404 for the
          # hidden discussion, and a throttled request costs no queries.
          authorize_note_creation!(parent_work_item)

          # Replies share the root note's confidentiality, so the root's readability decides the thread's.
          first_note = build_discussion_notes_relation(parent_work_item, params[:discussion_id]).first
          not_found!('Discussion') unless first_note&.readable_by?(current_user)

          # Work items are issues, so any non-system individual note can become a thread; no further check needed.
          unless first_note.to_discussion.can_reply_to_system_note?
            bad_request!('Replies to system notes are not allowed.')
          end

          create_authorized_work_item_note(parent_work_item, type: 'DiscussionNote',
            in_reply_to_discussion_id: params[:discussion_id]) do |note|
            present note, with: ::API::Entities::Note, current_user: current_user
          end
        end

        def render_discussion_note_for(parent_work_item)
          authorize_work_item_feature!(parent_work_item)
          authorize! :read_note, parent_work_item

          note = find_discussion_note!(parent_work_item)

          present note, with: ::API::Entities::Note, current_user: current_user
        end

        def update_discussion_note_for(parent_work_item)
          authorize_work_item_feature!(parent_work_item)
          authorize! :read_note, parent_work_item

          note = find_discussion_note!(parent_work_item)

          if params.key?(:resolved)
            resolve_discussion_note(parent_work_item, note)
          else
            update_note_body(parent_work_item, note)
          end
        end

        # Scoped to the work item's notes and the discussion, so a note id from another thread 404s.
        def find_discussion_note!(parent_work_item, preload: true)
          notes = build_discussion_notes_relation(parent_work_item, params[:discussion_id])
          # The entity preloads are wasted when the note is not presented, as on delete.
          notes = notes.unscope(:preload) unless preload # rubocop:disable CodeReuse/ActiveRecord -- undoes a preload
          note = notes.find_by_id(params[:note_id])
          not_found!('Note') unless note&.readable_by?(current_user)

          note
        end

        def update_note_body(parent_work_item, note)
          authorize! :update_note, note

          # Group-level work items have no project; the service accepts nil, as the legacy epic notes path does.
          note = ::Notes::UpdateService.new(parent_work_item.project, current_user, note: params[:body]).execute(note)

          process_note_creation_result(note) do
            present note, with: ::API::Entities::Note, current_user: current_user
          end
        end

        # Not called `resolve_note`: NotesHelpers already defines one that takes different arguments.
        def resolve_discussion_note(parent_work_item, note)
          authorize! :resolve_note, note

          bad_request!('Note is not resolvable') unless note.resolvable?

          if params[:resolved]
            ::Notes::ResolveService.new(parent_work_item.project, current_user).execute(note)
          else
            note.unresolve!
          end

          present note, with: ::API::Entities::Note, current_user: current_user
        end

        def delete_discussion_note_for(parent_work_item)
          authorize_work_item_feature!(parent_work_item)
          authorize! :read_note, parent_work_item

          note = find_discussion_note!(parent_work_item, preload: false)
          authorize! :delete_note, note

          destroy_conditionally!(note) do |note|
            # Group-level work items have no project; the service accepts nil, as the GraphQL mutation does.
            ::Notes::DestroyService.new(parent_work_item.project, current_user).execute(note)
          end
        end
      end

      resource :namespaces do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded full path of the namespace'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List notes in a discussion on a work item.' do
            detail 'Get a paginated list of notes in a single discussion thread on a work item in a namespace. ' \
              'Project and group namespaces are supported.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_discussion_notes_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }]

          get ':work_item_iid/discussions/:discussion_id/notes' do
            render_discussion_notes_for(work_item_for_namespace!(params[:id], params[:work_item_iid]))
          end

          desc 'Create a note in a discussion on a work item.' do
            detail 'Adds a reply to an existing discussion thread on a work item in a namespace. ' \
              'Project and group namespaces are supported.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_discussion_reply_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :create_note,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }]

          post ':work_item_iid/discussions/:discussion_id/notes' do
            reply_to_discussion_for(work_item_for_namespace!(params[:id], params[:work_item_iid]))
          end

          desc 'Get a note in a discussion on a work item.' do
            detail 'Get a single note from a discussion thread on a work item in a namespace. ' \
              'Project and group namespaces are supported.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_discussion_note_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }]

          get ':work_item_iid/discussions/:discussion_id/notes/:note_id' do
            render_discussion_note_for(work_item_for_namespace!(params[:id], params[:work_item_iid]))
          end

          desc 'Update a note in a discussion on a work item.' do
            detail 'Edit the body of a note or resolve/unresolve a single note in a discussion thread on a work item ' \
              'in a namespace. Project and group namespaces are supported.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_update_discussion_note_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_issue_discussion_note,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }]

          put ':work_item_iid/discussions/:discussion_id/notes/:note_id' do
            update_discussion_note_for(work_item_for_namespace!(params[:id], params[:work_item_iid]))
          end

          desc 'Delete a note from a discussion on a work item.' do
            detail 'Deletes a single note from a discussion thread on a work item in a namespace. ' \
              'Project and group namespaces are supported.'
            hidden true
            success code: 204
            failure DELETE_FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_discussion_note_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :delete_note,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }]

          delete ':work_item_iid/discussions/:discussion_id/notes/:note_id' do
            delete_discussion_note_for(work_item_for_namespace!(params[:id], params[:work_item_iid]))
          end
        end
      end

      resource :projects do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List notes in a discussion on a work item in a project.' do
            detail 'Get a paginated list of notes in a single discussion thread on a work item in a project.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_discussion_notes_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :project

          get ':work_item_iid/discussions/:discussion_id/notes' do
            render_discussion_notes_for(work_item_for!(find_project!(params[:id]), params[:work_item_iid]))
          end

          desc 'Create a note in a discussion on a work item in a project.' do
            detail 'Adds a reply to an existing discussion thread on a work item in a project.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_discussion_reply_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :create_note,
            boundary_type: :project

          post ':work_item_iid/discussions/:discussion_id/notes' do
            reply_to_discussion_for(work_item_for!(find_project!(params[:id]), params[:work_item_iid]))
          end

          desc 'Get a note in a discussion on a work item in a project.' do
            detail 'Get a single note from a discussion thread on a work item in a project.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_discussion_note_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :project

          get ':work_item_iid/discussions/:discussion_id/notes/:note_id' do
            render_discussion_note_for(work_item_for!(find_project!(params[:id]), params[:work_item_iid]))
          end

          desc 'Update a note in a discussion on a work item in a project.' do
            detail 'Edit the body of a note or resolve/unresolve a single note in a discussion thread on a work item ' \
              'in a project.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_update_discussion_note_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_issue_discussion_note,
            boundary_type: :project

          put ':work_item_iid/discussions/:discussion_id/notes/:note_id' do
            update_discussion_note_for(work_item_for!(find_project!(params[:id]), params[:work_item_iid]))
          end

          desc 'Delete a note from a discussion on a work item in a project.' do
            detail 'Deletes a single note from a discussion thread on a work item in a project.'
            hidden true
            success code: 204
            failure DELETE_FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_discussion_note_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :delete_note,
            boundary_type: :project

          delete ':work_item_iid/discussions/:discussion_id/notes/:note_id' do
            delete_discussion_note_for(work_item_for!(find_project!(params[:id]), params[:work_item_iid]))
          end
        end
      end

      resource :groups do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List notes in a discussion on a work item in a group.' do
            detail 'Get a paginated list of notes in a single discussion thread on a work item in a group.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_discussion_notes_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :group

          get ':work_item_iid/discussions/:discussion_id/notes' do
            render_discussion_notes_for(work_item_for!(find_group!(params[:id]), params[:work_item_iid]))
          end

          desc 'Create a note in a discussion on a work item in a group.' do
            detail 'Adds a reply to an existing discussion thread on a work item in a group.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_discussion_reply_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :create_note,
            boundary_type: :group

          post ':work_item_iid/discussions/:discussion_id/notes' do
            reply_to_discussion_for(work_item_for!(find_group!(params[:id]), params[:work_item_iid]))
          end

          desc 'Get a note in a discussion on a work item in a group.' do
            detail 'Get a single note from a discussion thread on a work item in a group.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_discussion_note_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :group

          get ':work_item_iid/discussions/:discussion_id/notes/:note_id' do
            render_discussion_note_for(work_item_for!(find_group!(params[:id]), params[:work_item_iid]))
          end

          desc 'Update a note in a discussion on a work item in a group.' do
            detail 'Edit the body of a note or resolve/unresolve a single note in a discussion thread on a work item ' \
              'in a group.'
            hidden true
            success ::API::Entities::Note
            failure FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_update_discussion_note_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :update_issue_discussion_note,
            boundary_type: :group

          put ':work_item_iid/discussions/:discussion_id/notes/:note_id' do
            update_discussion_note_for(work_item_for!(find_group!(params[:id]), params[:work_item_iid]))
          end

          desc 'Delete a note from a discussion on a work item in a group.' do
            detail 'Deletes a single note from a discussion thread on a work item in a group.'
            hidden true
            success code: 204
            failure DELETE_FAILURE_RESPONSES
            tags WORK_ITEMS_TAGS
          end

          params do
            use :work_item_discussion_note_params
          end

          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :delete_note,
            boundary_type: :group

          delete ':work_item_iid/discussions/:discussion_id/notes/:note_id' do
            delete_discussion_note_for(work_item_for!(find_group!(params[:id]), params[:work_item_iid]))
          end
        end
      end
    end
  end
end
