FactoryBot.define do
  factory :award_emoji do
    name { AwardEmoji::UPVOTE_NAMES.sample }
    user
    awardable factory: :issue

    after(:create) do |award, evaluator|
      award.awardable.project.add_guest(evaluator.user)
    end

    trait :upvote
    trait :downvote do
      name { AwardEmoji::DOWNVOTE_NAMES.sample }
    end
  end
end
