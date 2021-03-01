# frozen_string_literal: true

FactoryBot.define do
  factory :namespace do
    sequence(:name) { |n| "namespace#{n}" }
    path { name.downcase.gsub(/\s/, '_') }

    # This is a workaround to avoid the user creating another namespace via
    # User#ensure_namespace_correct. We should try to remove it and then
    # we could remove this workaround
    association :owner, factory: :user, strategy: :build
    before(:create) do |namespace|
      owner = namespace.owner

      if owner
        # We're changing the username here because we want to keep our path,
        # and User#ensure_namespace_correct would change the path based on
        # username, so we're forced to do this otherwise we'll need to change
        # a lot of existing tests.
        owner.username = namespace.path
        owner.namespace = namespace
      end
    end

    trait :with_aggregation_schedule do
      after(:create) do |namespace|
        create(:namespace_aggregation_schedules, namespace: namespace)
      end
    end

    trait :with_root_storage_statistics do
      after(:create) do |namespace|
        create(:namespace_root_storage_statistics, namespace: namespace)
      end
    end

    trait :with_namespace_settings do
      after(:create) do |namespace|
        create(:namespace_settings, namespace: namespace)
      end
    end

    trait :shared_runners_disabled do
      shared_runners_enabled { false }
    end

    trait :allow_descendants_override_disabled_shared_runners do
      allow_descendants_override_disabled_shared_runners { true }
    end
  end
end
