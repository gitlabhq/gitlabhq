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

    trait :with_namespace_settings do
      association :namespace_settings, factory: :namespace_settings
    end

    # Construct a hierarchy underneath the namespace.
    # Each namespace will have `children` amount of children,
    # and `depth` levels of descendants.
    trait :with_hierarchy do
      transient do
        children { 4 }
        depth    { 4 }
      end

      after(:create) do |namespace, evaluator|
        def create_graph(parent: nil, children: 4, depth: 4)
          return unless depth > 1

          children.times do
            factory_name = parent.model_name.singular
            child = FactoryBot.create(factory_name, parent: parent)
            create_graph(parent: child, children: children, depth: depth - 1)
          end

          parent
        end

        create_graph(
          parent:   namespace,
          children: evaluator.children,
          depth:    evaluator.depth
        )
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
