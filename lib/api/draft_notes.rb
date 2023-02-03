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
    end
  end
end
