class SystemNoteMetadata < ActiveRecord::Base
  ICON_TYPES = %w[
    commit description merge confidential visible label assignee cross_reference
    title time_tracking branch milestone discussion task moved opened closed merged
    approved unapproved
  ].freeze

  validates :note, presence: true
  validates :action, inclusion: ICON_TYPES, allow_nil: true

  belongs_to :note
end
