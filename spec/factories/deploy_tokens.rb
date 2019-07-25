# frozen_string_literal: true

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

    trait :gitlab_deploy_token do
      name DeployToken::GITLAB_DEPLOY_TOKEN_NAME
    end

    trait :expired do
      expires_at { Date.today - 1.month }
    end
  end
end
