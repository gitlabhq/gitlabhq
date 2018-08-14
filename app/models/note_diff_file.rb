# frozen_string_literal: true

class NoteDiffFile < ActiveRecord::Base
  include DiffFile

  belongs_to :diff_note, inverse_of: :note_diff_file

  validates :diff_note, presence: true
end
