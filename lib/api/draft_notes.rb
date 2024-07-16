# frozen_string_literal: true

module API
  class DraftNotes < ::API::Base
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

      params :positional do
        optional :position, type: Hash do
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

          optional :line_range, type: Hash, desc: 'Multi-line start and end' do
            optional :start, type: Hash do
              optional :line_code, type: String, desc: 'Start line code for multi-line note'
              optional :type, type: String, desc: 'Start line type for multi-line note'
              optional :old_line, type: String, desc: 'Start old_line line number'
              optional :new_line, type: String, desc: 'Start new_line line number'
            end
            optional :end, type: Hash do
              optional :line_code, type: String, desc: 'End line code for multi-line note'
              optional :type, type: String, desc: 'End line type for multi-line note'
              optional :old_line, type: String, desc: 'End old_line line number'
              optional :new_line, type: String, desc: 'End new_line line number'
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
      desc "Get a list of merge request draft notes" do
        success Entities::DraftNote
        is_array true
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :id,                type: String,  desc: "The ID of a project"
        requires :merge_request_iid, type: Integer, desc: "The ID of a merge request"
      end
      get ":id/merge_requests/:merge_request_iid/draft_notes", feature_category: :code_review_workflow do
        present load_draft_notes(params: params), with: Entities::DraftNote
      end

      desc "Get a single draft note" do
        success Entities::DraftNote
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :id,                type: String,  desc: "The ID of a project"
        requires :merge_request_iid, type: Integer, desc: "The ID of a merge request"
        requires :draft_note_id,     type: Integer, desc: "The ID of a draft note"
      end
      get ":id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id", feature_category: :code_review_workflow do
        draft_note = get_draft_note(params: params)

        if draft_note
          present draft_note, with: Entities::DraftNote
        else
          not_found!("Draft Note")
        end
      end

      desc "Create a new draft note" do
        success Entities::DraftNote
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
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

      desc "Modify an existing draft note" do
        success Entities::DraftNote
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :id,                type: String,  desc: "The ID of a project."
        requires :merge_request_iid, type: Integer, desc: "The ID of a merge request."
        requires :draft_note_id,     type: Integer, desc: "The ID of a draft note"
        optional :note,              type: String, allow_blank: false, desc: 'The content of a note.'
        use :positional
      end
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

      desc "Delete a draft note" do
        success Entities::DraftNote
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :id,                type: String,  desc: "The ID of a project"
        requires :merge_request_iid, type: Integer, desc: "The ID of a merge request"
        requires :draft_note_id,     type: Integer, desc: "The ID of a draft note"
      end
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

      desc "Publish a pending draft note" do
        success code: 204
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :id,                type: String,  desc: "The ID of a project"
        requires :merge_request_iid, type: Integer, desc: "The ID of a merge request"
        requires :draft_note_id,     type: Integer, desc: "The ID of a draft note"
      end
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

      desc "Bulk publish all pending draft notes" do
        success code: 204
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :id,                type: String,  desc: "The ID of a project"
        requires :merge_request_iid, type: Integer, desc: "The ID of a merge request"
      end
      post(
        ":id/merge_requests/:merge_request_iid/draft_notes/bulk_publish",
        feature_category: :code_review_workflow) do
        result = publish_draft_notes(params: params)

        if result[:status] == :success
          status 204
          body false
        else
          status 500
        end
      end
    end
  end
end
