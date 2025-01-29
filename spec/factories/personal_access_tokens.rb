# frozen_string_literal: true

FactoryBot.define do
  factory :personal_access_token do
    user
    organization
    sequence(:name) { |n| "PAT #{n}" }
    description { "Token description" }
    revoked { false }
    expires_at { 30.days.from_now }
    scopes { ['api'] }
    impersonation { false }

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

  factory :resource_access_token, parent: :personal_access_token do
    user { association :user, :project_bot }

    transient do
      rotated_at { 6.months.ago }
      resource { create(:group) } # rubocop:disable RSpec/FactoryBot/InlineAssociation -- this is not direct association of the factory created here
      access_level { Gitlab::Access::DEVELOPER }
    end

    after(:create) do |token, evaluator|
      evaluator.resource.add_member(token.user, evaluator.access_level)
    end

    trait :with_rotated_token do
      after(:create) do |token, evaluator|
        rotated_at = evaluator.rotated_at
        previous_access_token = create( # rubocop:disable RSpec/FactoryBot/StrategyInCallback -- this is not direct association of the factory created here
          :personal_access_token,
          :revoked,
          user: token.user,
          created_at: rotated_at - 6.months,
          expires_at: rotated_at,
          updated_at: rotated_at
        )

        token.update!(previous_personal_access_token_id: previous_access_token.id)
      end
    end
  end
end
