# frozen_string_literal: true

module DraftNotes
  class PublishService < DraftNotes::BaseService
    def execute(draft = nil)
      return error('Not allowed to create notes') unless can?(current_user, :create_note, merge_request)

      if draft
        publish_draft_note(draft)
      else
        publish_draft_notes
        merge_request_activity_counter.track_publish_review_action(user: current_user)
      end

      success
    rescue ActiveRecord::RecordInvalid => e
      message = "Unable to save #{e.record.class.name}: #{e.record.errors.full_messages.join(", ")} "
      error(message)
    end

    private

    def publish_draft_note(draft)
      create_note_from_draft(draft)
      draft.delete

      MergeRequests::ResolvedDiscussionNotificationService.new(project: project, current_user: current_user).execute(merge_request)
    end

    def publish_draft_notes
      return if draft_notes.empty?

      review = Review.create!(author: current_user, merge_request: merge_request, project: project)

      created_notes = draft_notes.map do |draft_note|
        draft_note.review = review
        create_note_from_draft(draft_note, skip_capture_diff_note_position: true)
      end

      capture_diff_note_positions(created_notes)
      draft_notes.delete_all
      set_reviewed
      notification_service.async.new_review(review)
      MergeRequests::ResolvedDiscussionNotificationService.new(project: project, current_user: current_user).execute(merge_request)
    end

    def create_note_from_draft(draft, skip_capture_diff_note_position: false)
      # Make sure the diff file is unfolded in order to find the correct line
      # codes.
      draft.diff_file&.unfold_diff_lines(draft.original_position)

      note = Notes::CreateService.new(draft.project, draft.author, draft.publish_params).execute(
        skip_capture_diff_note_position: skip_capture_diff_note_position
      )

      set_discussion_resolve_status(note, draft)
      note
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

    def set_reviewed
      ::MergeRequests::MarkReviewerReviewedService.new(project: project, current_user: current_user).execute(merge_request)
    end

    def capture_diff_note_positions(notes)
      paths = notes.flat_map do |note|
        note.diff_file&.paths if note.diff_note?
      end

      return if paths.empty?

      capture_service = Discussions::CaptureDiffNotePositionService.new(merge_request, paths.compact)

      notes.each do |note|
        capture_service.execute(note.discussion) if note.diff_note? && note.start_of_discussion?
      end
    end
  end
end
