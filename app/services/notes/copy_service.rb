# frozen_string_literal: true

# This service copies Notes from one Noteable to another.
#
# It expects the calling code to have performed the necessary authorization
# checks in order to allow the copy to happen.
module Notes
  class CopyService
    def initialize(current_user, from_noteable, to_noteable)
      raise ArgumentError, 'Noteables must be different' if from_noteable == to_noteable

      @current_user = current_user
      @from_noteable = from_noteable
      @to_noteable = to_noteable
      @from_project = from_noteable.project
      @new_discussion_ids = {}
    end

    def execute
      from_noteable.notes_with_associations.find_each do |note|
        copy_note(note)
      end

      ServiceResponse.success
    end

    private

    attr_reader :from_noteable, :to_noteable, :from_project, :current_user, :new_discussion_ids

    def copy_note(note)
      new_note = note.dup
      new_params = params_from_note(note, new_note)
      new_note.update!(new_params)

      copy_award_emoji(note, new_note)
    end

    def params_from_note(note, new_note)
      new_discussion_ids[note.discussion_id] ||= Discussion.discussion_id(new_note)
      rewritten_note = MarkdownContentRewriterService.new(current_user, note.note, from_project, to_noteable.resource_parent).execute

      new_params = {
        project: to_noteable.project,
        noteable: to_noteable,
        discussion_id: new_discussion_ids[note.discussion_id],
        note: rewritten_note,
        note_html: nil,
        created_at: note.created_at,
        updated_at: note.updated_at
      }

      if note.system_note_metadata
        new_params[:system_note_metadata] = note.system_note_metadata.dup

        # TODO: Implement copying of description versions when an issue is moved
        # https://gitlab.com/gitlab-org/gitlab/issues/32300
        new_params[:system_note_metadata].description_version = nil
      end

      new_params
    end

    def copy_award_emoji(from_note, to_note)
      AwardEmojis::CopyService.new(from_note, to_note).execute
    end
  end
end
