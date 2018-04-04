FactoryBot.define do
  factory :deploy_token do
    project
    token { SecureRandom.hex(50) }
    sequence(:name) { |n| "PDT #{n}" }
    revoked false
    expires_at { 5.days.from_now }
    scopes %w(read_repository read_registry)

    trait :revoked do
      revoked true
    end

    trait :read_repository do
      scopes ['read_repository']
    end

    trait :read_registry do
      scopes ['read_registry']
    end
  end
end
