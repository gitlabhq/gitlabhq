class NoteDiffFile < ApplicationRecord
  include DiffFile

  belongs_to :diff_note, inverse_of: :note_diff_file

  validates :diff_note, presence: true
end
