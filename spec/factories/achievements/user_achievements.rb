# frozen_string_literal: true

FactoryBot.define do
  factory :user_achievement, class: 'Achievements::UserAchievement' do
    user
    achievement
    awarded_by_user factory: :user
    priority { nil }

    trait :revoked do
      revoked_by_user factory: :user
      revoked_at { Time.now }
    end
  end
end
