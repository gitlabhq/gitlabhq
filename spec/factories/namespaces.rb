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
      association :aggregation_schedule, factory: :namespace_aggregation_schedules
    end

    trait :with_root_storage_statistics do
      association :root_storage_statistics, factory: :namespace_root_storage_statistics
    end
  end
end
