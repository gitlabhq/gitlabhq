FactoryBot.define do
  factory :user_preference do
    trait :only_comments do
      issue_discussion_filter { UserPreference::DISCUSSION_FILTERS[:comments] }
      merge_request_discussion_filter { UserPreference::DISCUSSION_FILTERS[:comments] }
    end
  end
end
