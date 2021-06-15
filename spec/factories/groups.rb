# frozen_string_literal: true

FactoryBot.define do
  factory :group, class: 'Group', parent: :namespace do
    sequence(:name) { |n| "group#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    type { 'Group' }
    owner { nil }
    project_creation_level { ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS }

    after(:create) do |group|
      if group.owner
        # We could remove this after we have proper constraint:
        # https://gitlab.com/gitlab-org/gitlab-foss/issues/43292
        raise "Don't set owner for groups, use `group.add_owner(user)` instead"
      end

      create(:namespace_settings, namespace: group) unless group.namespace_settings
    end

    trait :public do
      visibility_level { Gitlab::VisibilityLevel::PUBLIC }
    end

    trait :internal do
      visibility_level { Gitlab::VisibilityLevel::INTERNAL }
    end

    trait :private do
      visibility_level { Gitlab::VisibilityLevel::PRIVATE }
    end

    trait :with_avatar do
      avatar { fixture_file_upload('spec/fixtures/dk.png') }
    end

    trait :request_access_disabled do
      request_access_enabled { false }
    end

    trait :nested do
      parent factory: :group
    end

    trait :auto_devops_enabled do
      auto_devops_enabled { true }
    end

    trait :auto_devops_disabled do
      auto_devops_enabled { false }
    end

    trait :owner_subgroup_creation_only do
      subgroup_creation_level { ::Gitlab::Access::OWNER_SUBGROUP_ACCESS }
    end

    trait :shared_runners_disabled do
      shared_runners_enabled { false }
    end

    trait :with_export do
      after(:create) do |group, _evaluator|
        export_file = fixture_file_upload('spec/fixtures/group_export.tar.gz')
        create(:import_export_upload, group: group, export_file: export_file)
      end
    end

    trait :allow_descendants_override_disabled_shared_runners do
      allow_descendants_override_disabled_shared_runners { true }
    end

    # Construct a hierarchy underneath the group.
    # Each group will have `children` amount of children,
    # and `depth` levels of descendants.
    trait :with_hierarchy do
      transient do
        children { 4 }
        depth    { 4 }
      end

      after(:create) do |group, evaluator|
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
          parent:   group,
          children: evaluator.children,
          depth:    evaluator.depth
        )
      end
    end
  end
end
