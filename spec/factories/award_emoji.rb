# frozen_string_literal: true

FactoryBot.define do
  factory :award_emoji do
    name { AwardEmoji::THUMBS_UP }
    user
    awardable factory: :issue

    trait :upvote
    trait :downvote do
      name { AwardEmoji::THUMBS_DOWN }
    end
  end
end
