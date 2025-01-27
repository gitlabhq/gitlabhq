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
    color_mode_id { 1 }

    after(:build) do |user, evaluator|
      # UserWithNamespaceShim is not defined in gdk reset-data. We assume the shim is enabled in this case.
      assign_ns = if defined?(UserWithNamespaceShim)
                    UserWithNamespaceShim.enabled?
                  else
                    true
                  end

      if assign_ns
        org = user&.namespace&.organization ||
          Organizations::Organization
            .where(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
            .order(:created_at).first ||
          # We create an organization next even though we are building here. We need to ensure
          # that an organization exists so other entities can belong to the same organization
          create(:organization)

        user.assign_personal_namespace(org)
      end
    end

    trait :without_default_org do
      before(:create) { |user| user.define_singleton_method(:create_default_organization_user) { nil } }
    end

    trait :with_namespace do
      # rubocop: disable RSpec/FactoryBot/InlineAssociation -- We need to pass an Organization to this method
      namespace { assign_personal_namespace(create(:organization)) }
      # rubocop: enable RSpec/FactoryBot/InlineAssociation
    end

    trait :admin do
      admin { true }
    end

    # Set user as owner of all their organizations.
    # The intention of this trait is to work with the User #create_default_organization_user calllback. The callback
    # will be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/443611 and this trait will probably be moved to
    # the organization_user factory.
    trait :organization_owner do
      after(:create) do |user|
        user.organization_users.update_all(access_level: Gitlab::Access::OWNER)
      end
    end

    trait :public_email do
      public_email { email }
    end

    trait :notification_email do
      notification_email { email }
    end

    trait :private_profile do
      private_profile { true }
    end

    trait :blocked do
      after(:build) { |user, _| user.block! }
    end

    trait :locked do
      after(:build) do |user, _|
        Gitlab::ExclusiveLease.skipping_transaction_check { user.lock_access! }
      end
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

    trait :trusted do
      after(:create) do |user, _|
        user.custom_attributes.create!(
          key: UserCustomAttribute::TRUSTED_BY,
          value: "placeholder"
        )
      end
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
      name { 'Service account user' }
      user_type { :service_account }
      skip_confirmation { true }
      email { "#{User::SERVICE_ACCOUNT_PREFIX}_#{generate(:username)}@#{User::NOREPLY_EMAIL_DOMAIN}" }
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

    trait :duo_code_review_bot do
      user_type { :duo_code_review_bot }
    end

    trait :placeholder do
      user_type { :placeholder }
    end

    trait :import_user do
      user_type { :import_user }
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
        user.generate_otp_backup_codes!

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

    trait :invalid do
      first_name { 'A' * 130 } # Exceed `first_name` character limit in model to make it invalid
      to_create { |user| user.save!(validate: false) }
    end

    transient do
      # rubocop:disable Lint/EmptyBlock -- block is required by factorybot
      guest_of {}
      planner_of {}
      reporter_of {}
      developer_of {}
      maintainer_of {}
      owner_of {}
      # rubocop:enable Lint/EmptyBlock
    end

    after(:create) do |user, evaluator|
      Array.wrap(evaluator.guest_of).each { |target| target.add_guest(user) }
      Array.wrap(evaluator.planner_of).each { |target| target.add_planner(user) }
      Array.wrap(evaluator.reporter_of).each { |target| target.add_reporter(user) }
      Array.wrap(evaluator.developer_of).each { |target| target.add_developer(user) }
      Array.wrap(evaluator.maintainer_of).each { |target| target.add_maintainer(user) }
      Array.wrap(evaluator.owner_of).each { |target| target.add_owner(user) }
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
