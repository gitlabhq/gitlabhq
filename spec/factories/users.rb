# frozen_string_literal: true

FactoryBot.define do
  factory :user, aliases: [:author, :assignee, :recipient, :owner, :resource_owner] do
    email { generate(:email) }
    name { generate(:name) }
    username { generate(:username) }
    password "12345678"
    confirmed_at { Time.now }
    confirmation_token { nil }
    can_create_group true

    after(:stub) do |user|
      user.notification_email = user.email
    end

    trait :admin do
      admin true
    end

    trait :blocked do
      after(:build) { |user, _| user.block! }
    end

    trait :external do
      external true
    end

    trait :two_factor do
      two_factor_via_otp
    end

    trait :ghost do
      ghost true
      after(:build) { |user, _| user.block! }
    end

    trait :with_avatar do
      avatar { fixture_file_upload('spec/fixtures/dk.png') }
    end

    trait :two_factor_via_otp do
      before(:create) do |user|
        user.otp_required_for_login = true
        user.otp_secret = User.generate_otp_secret(32)
        user.otp_grace_period_started_at = Time.now
        user.generate_otp_backup_codes!
      end
    end

    trait :two_factor_via_u2f do
      transient { registrations_count 5 }

      after(:create) do |user, evaluator|
        create_list(:u2f_registration, evaluator.registrations_count, user: user)
      end
    end

    trait :readme do
      project_view :readme
    end

    trait :commit_email do
      after(:create) do |user, evaluator|
        additional = create(:email, :confirmed, user: user, email: "commit-#{user.email}")

        user.update!(commit_email: additional.email)
      end
    end

    transient do
      developer_projects []
    end

    after(:create) do |user, evaluator|
      evaluator.developer_projects.each do |project|
        project.add_developer(user)
      end
    end

    factory :omniauth_user do
      transient do
        extern_uid '123456'
        provider 'ldapmain'
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
    end

    factory :admin, traits: [:admin]
  end
end
