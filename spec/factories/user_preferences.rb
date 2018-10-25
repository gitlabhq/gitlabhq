# frozen_string_literal: true

FactoryBot.define do
  factory :user_preference do
    user

    trait :only_comments do
      issue_notes_filter { UserPreference::NOTES_FILTERS[:only_comments] }
      merge_request_notes_filter { UserPreference::NOTE_FILTERS[:only_comments] }
    end
  end
end
