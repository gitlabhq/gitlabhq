# frozen_string_literal: true

module API
  module WorkItems
    class DiscussionNotes < ::API::Base
      before { authenticate! }
      before { check_work_item_rest_api_feature_flag! }

      feature_category :portfolio_management
      urgency :low

      helpers ::API::Helpers::WorkItems::Authorization
      helpers ::API::Helpers::WorkItems::Preloads
      helpers ::API::Helpers::NotesHelpers

      helpers do
        def no_readable_notes_in_discussion?(parent_work_item)
          readable_discussion_notes(parent_work_item, params[:discussion_id]).empty?
        end

        params :work_item_discussion_notes_params do
          requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
          requires :discussion_id, type: String, desc: 'The ID of a discussion'
          optional :cursor, type: String, desc: 'Cursor for keyset pagination.'
          optional :per_page, type: Integer, default: 20, values: 1..100,
            desc: 'Number of notes to return per page (maximum 100).'
        end

        params :work_item_discussion_note_params do
          requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
          requires :discussion_id, type: String, desc: 'The ID of a discussion'
          requires :note_id, type: Integer, desc: 'The ID of a note'
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

        def render_discussion_note_for(parent_work_item)
          authorize_work_item_feature!(parent_work_item)
          authorize! :read_note, parent_work_item

          # Scoped to the work item's notes and the discussion, so a note id from another thread 404s.
          note = build_discussion_notes_relation(parent_work_item, params[:discussion_id]).find_by_id(params[:note_id])
          not_found!('Note') unless note&.readable_by?(current_user)

          present note, with: ::API::Entities::Note, current_user: current_user
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
        end
      end
    end
  end
end
