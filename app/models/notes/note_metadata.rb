# frozen_string_literal: true

module Notes
  class NoteMetadata < ApplicationRecord
    self.table_name = :note_metadata

    include Notes::WithAssociatedNote

    EMAIL_PARTICIPANT_LENGTH = 255

    belongs_to :note, inverse_of: :note_metadata

    alias_attribute :external_author, :email_participant

    before_save :ensure_email_participant_length

    private

    def ensure_email_participant_length
      return unless email_participant.present?

      self.email_participant = email_participant.truncate(EMAIL_PARTICIPANT_LENGTH)
    end

    def note_namespace_id
      return unless note

      note.namespace_id || namespace_id_for_noteable
    end

    def namespace_id_for_noteable
      if note.for_issue?
        note.noteable&.namespace_id
      elsif note.for_project_noteable?
        note.project&.project_namespace_id
      end
    end
  end
end
