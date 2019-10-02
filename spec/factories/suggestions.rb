# frozen_string_literal: true

FactoryBot.define do
  factory :suggestion do
    relative_order { 0 }
    association :note, factory: :diff_note_on_merge_request
    from_content { "    vars = {\n" }
    to_content { "    vars = [\n" }

    trait :unappliable do
      from_content { "foo" }
      to_content { "foo" }
    end

    trait :applied do
      applied { true }
      commit_id { RepoHelpers.sample_commit.id }
    end

    trait :content_from_repo do
      after(:build) do |suggestion, evaluator|
        suggestion.from_content = suggestion.fetch_from_content
      end
    end
  end
end
