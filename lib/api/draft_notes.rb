# frozen_string_literal: true

module API
  class DraftNotes < ::API::Base
    include APIGuard

    allow_access_with_scope :ai_workflows

    before { authenticate! }

    urgency :low

    helpers do
      def merge_request(params:)
        strong_memoize(:merge_request) do
          find_project_merge_request(params[:merge_request_iid])
        end
      end

      def load_draft_notes(params:)
        merge_request(params: params).draft_notes.authored_by(current_user)
      end

      def get_draft_note(params:)
        load_draft_notes(params: params).find(params[:draft_note_id])
      end

      def delete_draft_note(draft_note)
        ::DraftNotes::DestroyService
          .new(merge_request(params: params), current_user)
          .execute(draft_note)
      end

      def publish_draft_note(params:)
        ::DraftNotes::PublishService
          .new(merge_request(params: params), current_user)
          .execute(draft: get_draft_note(params: params))
      end

      def publish_draft_notes(params:)
        ::DraftNotes::PublishService
          .new(merge_request(params: params), current_user)
          .execute
      end

      def authorize_create_note!(params:)
        access_denied! unless can?(current_user, :create_note, merge_request(params: params))
      end

      def authorize_admin_draft!(draft_note)
        access_denied! unless can?(current_user, :admin_note, draft_note)
      end

      # rubocop:disable CodeReuse/ActiveRecord -- narrow update scoped to composite identity reviewer
      def update_composite_identity_reviewer_state(mr, state)
        composite_actor = ::Gitlab::Auth::Identity.resolve_composite_identity_actor(current_user)
        return unless composite_actor && composite_actor != current_user

        reviewer_record = mr.merge_request_reviewers.find_by(user_id: composite_actor.id)
        return unless reviewer_record

        state_value = MergeRequestReviewer.states[state]
        return unless state_value

        return if reviewer_record.update(state: state_value)

        Gitlab::AppLogger.warn(
          message: "Failed to update composite identity reviewer state",
          merge_request_id: mr.id,
          user_id: composite_actor.id,
          errors: reviewer_record.errors.full_messages
        )
      end
      # rubocop:enable CodeReuse/ActiveRecord

      # Requested changes is an EE-only concept. Overridden in EE to clear the caller's own
      # requested changes so a `reviewed` re-review unblocks merge. No-op in CE.
      def clear_requested_changes_on_review(mr); end

      params :positional do
        optional :position, type: Hash, desc: 'Position when creating a note' do
          requires :base_sha, type: String, desc: 'Base commit SHA in the source branch'
          requires :start_sha, type: String, desc: 'SHA referencing commit in target branch'
          requires :head_sha, type: String, desc: 'SHA referencing HEAD of this merge request'
          requires :position_type, type: String, desc: 'Type of the position reference', values: %w[text image file]
          optional :new_path, type: String, desc: 'File path after change'
          optional :new_line, type: Integer, desc: 'Line number after change'
          optional :old_path, type: String, desc: 'File path before change'
          optional :old_line, type: Integer, desc: 'Line number before change'
          optional :width, type: Integer, desc: 'Width of the image'
          optional :height, type: Integer, desc: 'Height of the image'
          optional :x, type: Integer, desc: 'X coordinate in the image'
          optional :y, type: Integer, desc: 'Y coordinate in the image'

          optional :line_range, type: Hash, desc: 'Line range for a multi-line note' do
            optional :start, type: Hash, desc: 'Start line for a multi-line note' do
              optional :line_code, type: String, desc: 'Start line code for multi-line note'
              optional :type, type: String, desc: 'Start line type for multi-line note'
              optional :old_line, type: Integer, desc: 'Start old_line line number'
              optional :new_line, type: Integer, desc: 'Start new_line line number'
            end
            optional :end, type: Hash, desc: 'End line for a multi-line note' do
              optional :line_code, type: String, desc: 'End line code for multi-line note'
              optional :type, type: String, desc: 'End line type for multi-line note'
              optional :old_line, type: Integer, desc: 'End old_line line number'
              optional :new_line, type: Integer, desc: 'End new_line line number'
            end
          end
        end
      end

      def draft_note_params
        {
          note: params[:note],
          position: params[:position],
          commit_id: params[:commit_id] == 'undefined' ? nil : params[:commit_id],
          resolve_discussion: params[:resolve_discussion] || false
        }
      end
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'List all merge request draft notes' do
        detail 'Lists all merge request draft notes.'
        success Entities::DraftNote
        is_array true
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags ['draft_notes']
      end
      params do
        requires :id,                type: String,  desc: "The ID of a project"
        requires :merge_request_iid, type: Integer, desc: "The ID of a merge request"
      end
      route_setting :authorization, permissions: :read_merge_request_draft_note, boundary_type: :project
      get ":id/merge_requests/:merge_request_iid/draft_notes", feature_category: :code_review_workflow do
        present load_draft_notes(params: params), with: Entities::DraftNote
      end

      desc 'Retrieve a draft note' do
        detail 'Retrieves a draft note for a specified merge request.'
        success Entities::DraftNote
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags ['draft_notes']
      end
      params do
        requires :id,                type: String,  desc: "The ID of a project"
        requires :merge_request_iid, type: Integer, desc: "The ID of a merge request"
        requires :draft_note_id,     type: Integer, desc: "The ID of a draft note"
      end
      route_setting :authorization, permissions: :read_merge_request_draft_note, boundary_type: :project
      get ":id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id", feature_category: :code_review_workflow do
        draft_note = get_draft_note(params: params)

        if draft_note
          present draft_note, with: Entities::DraftNote
        else
          not_found!("Draft Note")
        end
      end

      desc 'Create a draft note' do
        detail 'Creates a draft note for a specified merge request.'
        success Entities::DraftNote
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags ['draft_notes']
      end
      params do
        requires :id,                        type: String,  desc: "The ID of a project."
        requires :merge_request_iid,         type: Integer, desc: "The ID of a merge request."
        requires :note,                      type: String,  desc: 'The content of a note.'
        optional :in_reply_to_discussion_id, type: String,  desc: 'The ID of a discussion the draft note replies to.'
        optional :commit_id,                 type: String,  desc: 'The sha of a commit to associate the draft note to.'
        optional :resolve_discussion,        type: Boolean, desc: 'The associated discussion should be resolved.'
        use :positional
      end
      route_setting :authorization, permissions: :create_merge_request_draft_note, boundary_type: :project
      post ":id/merge_requests/:merge_request_iid/draft_notes", feature_category: :code_review_workflow do
        authorize_create_note!(params: params)

        create_params = draft_note_params.merge(in_reply_to_discussion_id: params[:in_reply_to_discussion_id])
        create_service = ::DraftNotes::CreateService.new(merge_request(params: params), current_user, create_params)

        draft_note = create_service.execute

        if draft_note.persisted?
          present draft_note, with: Entities::DraftNote
        else
          render_validation_error!(draft_note)
        end
      end

      desc 'Update a draft note' do
        detail 'Updates a draft note for a specified merge request.'
        success Entities::DraftNote
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags ['draft_notes']
      end
      params do
        requires :id,                type: String,  desc: "The ID of a project."
        requires :merge_request_iid, type: Integer, desc: "The ID of a merge request."
        requires :draft_note_id,     type: Integer, desc: "The ID of a draft note"
        optional :note,              type: String, allow_blank: false, desc: 'The content of a note.'
        use :positional
      end
      route_setting :authorization, permissions: :update_merge_request_draft_note, boundary_type: :project
      put ":id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id", feature_category: :code_review_workflow do
        bad_request!('Missing params to modify') unless params[:note].present?

        draft_note = get_draft_note(params: params)

        if draft_note
          authorize_admin_draft!(draft_note)

          draft_note.update!(note: params[:note], position: params[:position])
          present draft_note, with: Entities::DraftNote
        else
          not_found!("Draft Note")
        end
      end

      desc 'Delete a draft note' do
        detail 'Deletes a draft note for a specified merge request.'
        success Entities::DraftNote
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags ['draft_notes']
      end
      params do
        requires :id,                type: String,  desc: "The ID of a project"
        requires :merge_request_iid, type: Integer, desc: "The ID of a merge request"
        requires :draft_note_id,     type: Integer, desc: "The ID of a draft note"
      end
      route_setting :authorization, permissions: :delete_merge_request_draft_note, boundary_type: :project
      delete(
        ":id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id",
        feature_category: :code_review_workflow) do
        draft_note = get_draft_note(params: params)

        if draft_note
          delete_draft_note(draft_note)
          status 204
          body false
        else
          not_found!("Draft Note")
        end
      end

      desc 'Publish a draft note' do
        detail 'Publishes a draft note for a specified merge request.'
        success code: 204
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags ['draft_notes']
      end
      params do
        requires :id,                type: String,  desc: "The ID of a project"
        requires :merge_request_iid, type: Integer, desc: "The ID of a merge request"
        requires :draft_note_id,     type: Integer, desc: "The ID of a draft note"
      end
      route_setting :authorization, permissions: :publish_merge_request_draft_note, boundary_type: :project
      put(
        ":id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id/publish",
        feature_category: :code_review_workflow) do
        result = publish_draft_note(params: params)

        if result[:status] == :success
          status 204
          body false
        else
          status 500
        end
      end

      desc 'Publish all pending draft notes' do
        detail 'Publishes all pending draft notes for the current user on the specified merge request. ' \
          'Optionally sets the reviewer state and posts a summary note.'
        success code: 204
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags ['draft_notes']
      end
      params do
        requires :id, type: String, desc: "The ID of a project"
        requires :merge_request_iid, type: Integer, desc: "The ID of a merge request"
        optional :reviewer_state, type: String,
          desc: "Set reviewer review state after publishing. Does not record a formal approval",
          values: %w[requested_changes reviewed]
        optional :note, type: String, desc: "Summary note body to post on the merge request"
        optional :internal, type: Boolean, desc: "If true, the summary note is internal",
          default: false
      end
      route_setting :authorization, permissions: :publish_merge_request_draft_note, boundary_type: :project
      post(
        ":id/merge_requests/:merge_request_iid/draft_notes/bulk_publish",
        feature_category: :code_review_workflow) do
        result = publish_draft_notes(params: params)

        render_api_error!(result[:message], :internal_server_error) unless result[:status] == :success

        if params[:note].present?
          opts = {
            note: params[:note],
            noteable_type: 'MergeRequest',
            noteable_id: merge_request(params: params).id,
            internal: params[:internal]
          }
          note = ::Notes::CreateService.new(user_project, current_user, opts).execute
          render_api_error!(note.errors.full_messages.join(', '), :unprocessable_entity) unless note.persisted?
        end

        if params[:reviewer_state].present?
          mr = merge_request(params: params)

          # A prior review may have set `requested_changes`, which blocks merge until the
          # record is destroyed. Setting the reviewer state to `reviewed` does not clear it
          # (only `approved` does, via UpdateReviewerStateService), so a clean re-review would
          # leave the merge request blocked. Clear the caller's own requested changes here so a
          # `reviewed` re-review can unblock without recording a formal approval. No-op in CE.
          clear_requested_changes_on_review(mr) if params[:reviewer_state] == 'reviewed'

          ::MergeRequests::UpdateReviewerStateService
            .new(project: user_project, current_user: current_user)
            .execute(mr, params[:reviewer_state])

          update_composite_identity_reviewer_state(mr, params[:reviewer_state])
        end

        status 204
        body false
      end
    end
  end
end

API::DraftNotes.prepend_mod_with('API::DraftNotes')
