# frozen_string_literal: true

FactoryBot.define do
  factory :note_metadata, class: 'Notes::NoteMetadata' do
    note
    email_participant { 'user@example.com' }
  end
end
