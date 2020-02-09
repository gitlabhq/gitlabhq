# frozen_string_literal: true

module API
  module Entities
    class CommitNote < Grape::Entity
      expose :note
      expose(:path) { |note| note.diff_file.try(:file_path) if note.diff_note? }
      expose(:line) { |note| note.diff_line.try(:new_line) if note.diff_note? }
      expose(:line_type) { |note| note.diff_line.try(:type) if note.diff_note? }
      expose :author, using: Entities::UserBasic
      expose :created_at
    end
  end
end
