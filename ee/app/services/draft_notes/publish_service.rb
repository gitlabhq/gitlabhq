# frozen_string_literal: true

module DraftNotes
  class PublishService < DraftNotes::BaseService
    def execute(draft_id = nil)
      if draft_id
        publish_draft_note(draft_id)
      else
        publish_draft_notes
      end
    end

    private

    def publish_draft_note(draft_id)
      draft = DraftNote.find(draft_id)

      create_note_from_draft(draft)
      draft.delete

      MergeRequests::ResolvedDiscussionNotificationService.new(project, current_user).execute(merge_request)
    end

    def publish_draft_notes
      draft_notes.each(&method(:create_note_from_draft))
      draft_notes.delete_all

      MergeRequests::ResolvedDiscussionNotificationService.new(project, current_user).execute(merge_request)
    end

    def create_note_from_draft(draft)
      note = Notes::CreateService.new(draft.project, draft.author, draft.publish_params).execute
      set_discussion_resolve_status(note, draft)
    end

    def set_discussion_resolve_status(note, draft_note)
      return unless draft_note.discussion_id.present?

      discussion = note.discussion

      if draft_note.resolve_discussion && discussion.can_resolve?(current_user)
        discussion.resolve!(current_user)
      else
        discussion.unresolve!
      end
    end

    def draft_notes
      @draft_notes ||= merge_request.draft_notes.authored_by(current_user)
    end
  end
end
