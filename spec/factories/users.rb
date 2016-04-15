FactoryGirl.define do
  sequence(:name) { FFaker::Name.name }

  factory :user, aliases: [:author, :assignee, :recipient, :owner, :creator, :resource_owner] do
    email { FFaker::Internet.email }
    name
    sequence(:username) { |n| "#{FFaker::Internet.user_name}#{n}" }
    password "12345678"
    confirmed_at { Time.now }
    confirmation_token { nil }
    can_create_group true

    trait :admin do
      admin true
    end

    trait :two_factor do
      before(:create) do |user|
        user.two_factor_enabled = true
        user.otp_secret = User.generate_otp_secret(32)
        user.otp_grace_period_started_at = Time.now
        user.generate_otp_backup_codes!
      end
    end

    factory :omniauth_user do
      transient do
        extern_uid '123456'
        provider 'ldapmain'
      end

      after(:create) do |user, evaluator|
        user.identities << create(
          :identity,
          provider: evaluator.provider,
          extern_uid: evaluator.extern_uid
        )
      end
    end

    factory :admin, traits: [:admin]
  end
end
