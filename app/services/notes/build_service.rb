# frozen_string_literal: true

module Notes
  class BuildService < ::BaseService
    def execute
      in_reply_to_discussion_id = params.delete(:in_reply_to_discussion_id)
      external_author = params.delete(:external_author)

      discussion = nil

      if external_author.present?
        note_metadata = Notes::NoteMetadata.new(email_participant: external_author)
        params[:note_metadata] = note_metadata
      end

      if in_reply_to_discussion_id.present?
        discussion = find_discussion(in_reply_to_discussion_id)

        return discussion_not_found unless discussion && can?(current_user, :create_note, discussion.noteable)

        discussion = discussion.convert_to_discussion! if discussion.can_convert_to_discussion?

        params.merge!(discussion.reply_attributes)
      end

      # The `confidential` param for notes is deprecated with 15.3
      # and renamed to `internal`.
      # We still accept `confidential` until the param gets removed from the API.
      # Until we have not migrated the database column to `internal` we need to rename
      # the parameter. Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/367923.
      params[:confidential] = params[:internal] || params[:confidential]
      params.delete(:internal)

      new_note(params, discussion)
    end

    private

    def new_note(params, discussion)
      note = Note.new(params)
      note.project = project
      note.author = current_user

      parent_confidential = discussion&.confidential?
      can_set_confidential = can?(current_user, :mark_note_as_internal, note)

      return discussion_not_found if parent_confidential && !can_set_confidential

      note.confidential = (parent_confidential.nil? && can_set_confidential ? params.delete(:confidential) : parent_confidential)
      note.resolve_without_save(current_user) if discussion&.resolved?
      note
    end

    def find_discussion(discussion_id)
      if project
        project.notes.find_discussion(discussion_id)
      else
        Note.find_discussion(discussion_id)
      end
    end

    def discussion_not_found
      note = Note.new
      note.errors.add(:base, _('Discussion to reply to cannot be found'))
      note
    end
  end
end
