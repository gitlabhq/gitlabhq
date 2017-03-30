class SystemNoteMetadata < ActiveRecord::Base
  ICON_TYPES = %w[
    commit merge confidentiality status label assignee cross_reference
<<<<<<< HEAD
    title time_tracking branch milestone discussion task moved approvals
=======
    title time_tracking branch milestone discussion task moved
>>>>>>> ce/master
  ].freeze

  validates :note, presence: true
  validates :action, inclusion: ICON_TYPES, allow_nil: true

  belongs_to :note
end
