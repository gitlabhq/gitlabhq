FactoryBot.define do
  factory :award_emoji do
    name "thumbsup"
    user
    awardable factory: :issue

    trait :upvote
    trait :downvote do
      name "thumbsdown"
    end
  end
end
