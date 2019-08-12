# frozen_string_literal: true

class SystemNoteMetadata < ApplicationRecord
  # These notes's action text might contain a reference that is external.
  # We should always force a deep validation upon references that are found
  # in this note type.
  # Other notes can always be safely shown as all its references are
  # in the same project (i.e. with the same permissions)
  TYPES_WITH_CROSS_REFERENCES = %w[
    commit cross_reference
    close duplicate
    moved merge
  ].freeze

  ICON_TYPES = %w[
    commit description merge confidential visible label assignee cross_reference
    title time_tracking branch milestone discussion task moved
    opened closed merged duplicate locked unlocked
    outdated tag due_date
  ].freeze

  validates :note, presence: true
  validates :action, inclusion: { in: :icon_types }, allow_nil: true

  belongs_to :note

  def icon_types
    ICON_TYPES
  end

  def cross_reference_types
    TYPES_WITH_CROSS_REFERENCES
  end
end
