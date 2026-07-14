# frozen_string_literal: true

# When adding or changing attributes, consider changing the database importer as well
# lib/gitlab/database_importers/default_organization_importer.rb
FactoryBot.define do
  factory :organization, class: 'Organizations::Organization' do
    sequence(:name) { |n| "Organization ##{n}" }
    path { name.parameterize }
    uuid { Gitlab::Utils.uuid_v7 }

    visibility_level { Organizations::Organization::PUBLIC }
    state { :active }

    transient do
      # rubocop:disable Lint/EmptyBlock -- block is required by factorybot
      owners {}
      # rubocop:enable Lint/EmptyBlock
    end

    after(:create) do |organization, evaluator|
      Array.wrap(evaluator.owners).each { |user| organization.add_owner(user) }
    end

    # The default organization ID is for specs that specifically target the default organization.
    # Most specs should just create a normal organization.
    trait :default do
      id { Organizations::Organization::DEFAULT_ORGANIZATION_ID }
      name { 'Default' }
      uuid { '00000000-0000-7000-8000-000000000001' }
      visibility_level { Organizations::Organization::PUBLIC }

      initialize_with do
        # Ensure we only use one default organization
        default_org = Organizations::Organization
          .where(id: Organizations::Organization::DEFAULT_ORGANIZATION_ID)
          .first_or_initialize
        default_org.attributes = attributes.except(:id)
        default_org
      end
    end

    trait :public do
      visibility_level { Organizations::Organization::PUBLIC }
    end

    trait :private do
      visibility_level { Organizations::Organization::PRIVATE }
    end

    trait :isolated do
      isolated_record { association(:organization_isolation, :isolated) }
    end

    trait :unconfirmed do
      state { :unconfirmed }
    end

    trait :confirmed do
      state { :confirmed }

      after(:create) do |organization, evaluator|
        confirming_user = Array.wrap(evaluator.owners).first
        next unless confirming_user

        organization.state_metadata.merge!(
          'confirmed_at' => Time.current.as_json,
          'confirmed_by_user_id' => confirming_user.id
        )
        organization.organization_detail.save!
      end
    end
  end
end

FactoryBot.define do
  factory :common_organization, class: 'Organizations::Organization' do
    skip_create

    initialize_with do
      Organizations::Organization.find_or_create_by!(path: 'common-org') do |org|
        org.name = 'Common Organization'
        # This should be PRIVATE: https://gitlab.com/gitlab-org/gitlab/-/issues/556368
        org.visibility_level = Organizations::Organization::PUBLIC
      end
    end
  end
end
