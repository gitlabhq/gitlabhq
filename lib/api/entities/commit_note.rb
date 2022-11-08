# frozen_string_literal: true

module API
  module Entities
    class CommitNote < Grape::Entity
      expose :note, documentation: { type: 'string', example: 'this doc is really nice' }

      expose :path, documentation: { type: 'string', example: 'README.md' } do |note|
        note.diff_file.try(:file_path) if note.diff_note?
      end

      expose :line, documentation: { type: 'integer', example: 11 } do |note|
        note.diff_line.try(:line) if note.diff_note?
      end

      expose :line_type, documentation: { type: 'string', example: 'new' } do |note|
        note.diff_line.try(:type) if note.diff_note?
      end

      expose :author, using: Entities::UserBasic
      expose :created_at, documentation: { type: 'dateTime', example: '2016-01-19T09:44:55.600Z' }
    end
  end
end
