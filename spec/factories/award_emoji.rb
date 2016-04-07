FactoryGirl.define do
  factory :award_emoji do
    name "thumbsup"
    user
    awardable factory: :issue

    trait :thumbs_up
    trait :upvote

    trait :thumbs_down do
      name "thumbsdown"
    end

    trait :downvote do
      name "thumbsdown"
    end
  end
end
