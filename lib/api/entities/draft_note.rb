# frozen_string_literal: true

module API
  module Entities
    class DraftNote < Grape::Entity
      expose :id, documentation: { type: 'Integer', format: 'int64', example: 2 }
      expose :author_id, documentation: { type: 'Integer', format: 'int64', example: 4 }
      expose :merge_request_id,   documentation: { type: 'Integer', format: 'int64', example: 52 }
      expose :resolve_discussion, documentation: { type: 'Boolean', example: true }
      expose :discussion_id, documentation: { type: 'String', example: '6a9c1750b37d513a43987b574953fceb50b03ce7' }
      expose :note, documentation: { type: 'String', example: 'This is a note' }
      expose :commit_id, documentation: { type: 'String', example: '6104942438c14ec7bd21c6cd5bd995272b3faff6' }
      expose :line_code, documentation: { type: 'String', example: '1c497fbb3a46b78edf0_2_4' }
      expose :position, documentation: {
        type: 'Hash',
        example: {
          base_sha: "aa149113",
          start_sha: "b3a0a8c4",
          head_sha: "be3020c7",
          old_path: "example.md",
          new_path: "example.md",
          position_type: "text",
          old_line: 2,
          new_line: 4,
          line_range: {
            start: {
              line_code: "1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_2_4",
              type: nil,
              old_line: 2,
              new_line: 4
            },
            end: {
              line_code: "1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_2_4",
              type: nil,
              old_line: 2,
              new_line: 4
            }
          }
        }
      } do |note|
        note.position.to_h.except(:ignore_whitespace_change)
      end
    end
  end
end
