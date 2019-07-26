# frozen_string_literal: true

FactoryBot.define do
  factory :personal_access_token do
    user
    sequence(:name) { |n| "PAT #{n}" }
    revoked false
    expires_at { 5.days.from_now }
    scopes ['api']
    impersonation false

    after(:build) { |personal_access_token| personal_access_token.ensure_token }

    trait :impersonation do
      impersonation true
    end

    trait :revoked do
      revoked true
    end

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :invalid do
      token_digest nil
    end
  end
end
