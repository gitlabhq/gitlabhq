# frozen_string_literal: true

FactoryBot.define do
  factory :diff_note_position do
    association :note, factory: :diff_note_on_merge_request
    line_code { note.line_code }
    position { note.position }
    diff_type { :head }
  end
end
