# frozen_string_literal: true

FactoryBot.define do
  factory :personal_access_token do
    user
    sequence(:name) { |n| "PAT #{n}" }
    revoked { false }
    expires_at { 30.days.from_now }
    scopes { ['api'] }
    impersonation { false }

    after(:build) { |personal_access_token| personal_access_token.ensure_token }

    trait :impersonation do
      impersonation { true }
    end

    trait :revoked do
      revoked { true }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :invalid do
      token_digest { nil }
    end

    trait :admin_mode do
      before(:create) do |personal_access_token|
        personal_access_token.scopes.append(Gitlab::Auth::ADMIN_MODE_SCOPE) if personal_access_token.user.admin?
      end
    end

    trait :no_prefix do
      after(:build) { |personal_access_token| personal_access_token.set_token(Devise.friendly_token) }
    end

    trait :dependency_proxy_scopes do
      before(:create) do |personal_access_token|
        personal_access_token.scopes = (personal_access_token.scopes + Gitlab::Auth::REPOSITORY_SCOPES).uniq
      end
    end
  end
end
