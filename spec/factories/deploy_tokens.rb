FactoryBot.define do
  factory :deploy_token do
    token { SecureRandom.hex(50) }
    sequence(:name) { |n| "PDT #{n}" }
    read_repository true
    read_registry true
    revoked false
    expires_at { 5.days.from_now }

    trait :revoked do
      revoked true
    end
  end
end
