FactoryBot.define do
  factory :deploy_token do
    project
    token { SecureRandom.hex(50) }
    sequence(:name) { |n| "PDT #{n}" }
    revoked false
    expires_at { 5.days.from_now }
    scopes %w(read_repo read_registry)

    trait :revoked do
      revoked true
    end

    trait :read_repo do
      scopes ['read_repo']
    end

    trait :read_registry do
      scopes ['read_registry']
    end
  end
end
