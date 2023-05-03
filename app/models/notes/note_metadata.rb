# frozen_string_literal: true

module Notes
  class NoteMetadata < ApplicationRecord
    self.table_name = :note_metadata

    belongs_to :note, inverse_of: :note_metadata
    validates :email_participant, length: { maximum: 255 }

    alias_attribute :external_author, :email_participant
  end
end
