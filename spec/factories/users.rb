# frozen_string_literal: true

FactoryBot.define do
  factory :user, aliases: [:author, :assignee, :recipient, :owner, :resource_owner] do
    email { generate(:email) }
    name { generate(:name) }
    username { generate(:username) }
    password { User.random_password }
    role { 'software_developer' }
    confirmed_at { Time.now }
    confirmation_token { nil }
    can_create_group { true }
    color_scheme_id { 1 }

    trait :admin do
      admin { true }
    end

    trait :public_email do
      public_email { email }
    end

    trait :private_profile do
      private_profile { true }
    end

    trait :blocked do
      after(:build) { |user, _| user.block! }
    end

    trait :locked do
      after(:build) { |user, _| user.lock_access! }
    end

    trait :disallowed_password do
      password { User::DISALLOWED_PASSWORDS.first }
    end

    trait :blocked_pending_approval do
      after(:build) { |user, _| user.block_pending_approval! }
    end

    trait :banned do
      after(:build) { |user, _| user.ban! }
    end

    trait :ldap_blocked do
      after(:build) { |user, _| user.ldap_block! }
    end

    trait :bot do
      user_type { :alert_bot }
    end

    trait :deactivated do
      after(:build) { |user, _| user.deactivate! }
    end

    trait :project_bot do
      user_type { :project_bot }
    end

    trait :service_account do
      user_type { :service_account }
    end

    trait :migration_bot do
      user_type { :migration_bot }
    end

    trait :security_bot do
      user_type { :security_bot }
    end

    trait :llm_bot do
      user_type { :llm_bot }
    end

    trait :external do
      external { true }
    end

    trait :two_factor do
      two_factor_via_otp
    end

    trait :ghost do
      user_type { :ghost }
      after(:build) { |user, _| user.block! }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :with_avatar do
      avatar { fixture_file_upload('spec/fixtures/dk.png') }
    end

    trait :with_sign_ins do
      sign_in_count { 3 }
      current_sign_in_at { FFaker::Time.between(10.days.ago, 1.day.ago) }
      last_sign_in_at { FFaker::Time.between(10.days.ago, 1.day.ago) }
      current_sign_in_ip { '127.0.0.1' }
      last_sign_in_ip { '127.0.0.1' }
    end

    trait :with_credit_card_validation do
      after :create do |user|
        create :credit_card_validation, user: user
      end
    end

    trait :two_factor_via_otp do
      before(:create) do |user|
        user.otp_required_for_login = true
        user.otp_secret = User.generate_otp_secret(32)
        user.otp_grace_period_started_at = Time.now
        user.generate_otp_backup_codes!
      end
    end

    trait :two_factor_via_webauthn do
      transient { registrations_count { 5 } }

      after(:create) do |user, evaluator|
        create_list(:webauthn_registration, evaluator.registrations_count, user: user)
      end
    end

    trait :readme do
      project_view { :readme }
    end

    trait :commit_email do
      after(:create) do |user, evaluator|
        additional = create(:email, :confirmed, user: user, email: "commit-#{user.email}")

        user.update!(commit_email: additional.email)
      end
    end

    transient do
      developer_projects { [] }
      maintainer_projects { [] }
    end

    after(:create) do |user, evaluator|
      evaluator.developer_projects.each do |project|
        project.add_developer(user)
      end

      evaluator.maintainer_projects.each do |project|
        project.add_maintainer(user)
      end
    end

    factory :omniauth_user do
      password_automatically_set { true }

      transient do
        extern_uid { '123456' }
        provider { 'twitter' }
      end

      after(:create) do |user, evaluator|
        identity_attrs = {
          provider: evaluator.provider,
          extern_uid: evaluator.extern_uid
        }

        if evaluator.respond_to?(:saml_provider)
          identity_attrs[:saml_provider] = evaluator.saml_provider
        end

        user.identities << create(:identity, identity_attrs)
      end

      trait :ldap do
        transient do
          provider { 'ldapmain' }
        end
      end

      trait :unconfirmed do
        confirmed_at { nil }
      end
    end

    factory :atlassian_user do
      transient do
        extern_uid { generate(:username) }
      end

      after(:create) do |user, evaluator|
        create(:atlassian_identity, user: user, extern_uid: evaluator.extern_uid)
      end
    end

    factory :admin, traits: [:admin]
  end
end
