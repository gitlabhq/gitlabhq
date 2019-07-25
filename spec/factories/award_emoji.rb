# frozen_string_literal: true

FactoryBot.define do
  factory :award_emoji do
    name "thumbsup"
    user
    awardable factory: :issue

    after(:create) do |award, evaluator|
      award.awardable.project&.add_guest(evaluator.user)
    end

    trait :upvote
    trait :downvote do
      name "thumbsdown"
    end
  end
end
