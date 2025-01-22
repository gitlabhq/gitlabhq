# frozen_string_literal: true

class SystemNoteMetadata < ApplicationRecord
  include Importable

  # These notes's action text might contain a reference that is external.
  # We should always force a deep validation upon references that are found
  # in this note type.
  # Other notes can always be safely shown as all its references are
  # in the same project (i.e. with the same permissions)
  TYPES_WITH_CROSS_REFERENCES = %w[
    commit cross_reference
    closed duplicate
    moved merge
    label milestone
    relate unrelate
    unrelate_from_parent
    unrelate_from_child
    relate_to_parent
    relate_to_child
    cloned
  ].freeze

  ICON_TYPES = %w[
    commit description merge confidential visible label assignee cross_reference
    designs_added designs_modified designs_removed designs_discussion_added
    title time_tracking branch milestone discussion task moved cloned
    opened closed merged duplicate locked unlocked outdated reviewer
    tag due_date start_date_or_due_date pinned_embed cherry_pick health_status approved unapproved
    status alert_issue_added relate unrelate new_alert_added severity contact timeline_event
    issue_type relate_to_child unrelate_from_child relate_to_parent unrelate_from_parent override
    issue_email_participants requested_changes
  ].freeze

  validates :note, presence: true, unless: :importing?
  validates :action, inclusion: { in: :icon_types }, allow_nil: true

  belongs_to :note
  belongs_to :description_version

  scope :for_notes, ->(notes) { where(note_id: notes) }
  delegate_missing_to :note

  def declarative_policy_delegate
    note
  end

  def icon_types
    ICON_TYPES
  end

  def cross_reference_types
    TYPES_WITH_CROSS_REFERENCES
  end
end

SystemNoteMetadata.prepend_mod_with('SystemNoteMetadata')
