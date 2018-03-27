FactoryBot.define do
  factory :personal_access_token do
    user
    token { SecureRandom.hex(50) }
    sequence(:name) { |n| "PAT #{n}" }
    revoked false
    expires_at { 5.days.from_now }
    scopes ['api']
    impersonation false

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
      token nil
    end
  end
end
