# frozen_string_literal: true

FactoryBot.define do
  factory :group, class: 'Group', parent: :namespace do
    sequence(:name) { |n| "group#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    type { Group.sti_name }
    owner { nil }
    project_creation_level { ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS }

    transient do
      # rubocop:disable Lint/EmptyBlock -- block is required by factorybot
      guests {}
      planners {}
      reporters {}
      developers {}
      maintainers {}
      owners {}
      creator {}
      # rubocop:enable Lint/EmptyBlock
    end

    after(:create) do |group, evaluator|
      if group.owner
        # We could remove this after we have proper constraint:
        # https://gitlab.com/gitlab-org/gitlab-foss/issues/43292
        raise "Don't set owner for groups, use `group.add_owner(user)` instead"
      end

      create(:namespace_settings, namespace: group) unless group.namespace_settings

      group.add_members(Array.wrap(evaluator.guests), :guest)
      group.add_members(Array.wrap(evaluator.planners), :planner)
      group.add_members(Array.wrap(evaluator.reporters), :reporter)
      group.add_members(Array.wrap(evaluator.developers), :developer)
      group.add_members(Array.wrap(evaluator.maintainers), :maintainer)
      group.add_members(Array.wrap(evaluator.owners), :owner)
      group.add_creator(evaluator.creator) if evaluator.creator
    end

    trait :with_organization do
      association :organization
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

    trait :shared_runners_disabled_and_unoverridable do
      shared_runners_disabled
      allow_descendants_override_disabled_shared_runners { false }
    end

    trait :shared_runners_disabled_and_overridable do
      shared_runners_disabled
      allow_descendants_override_disabled_shared_runners { true }
    end

    trait :shared_runners_enabled do
      shared_runners_enabled { true }
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
            child = create(factory_name, parent: parent, organization: parent.organization)
            create_graph(parent: child, children: children, depth: depth - 1)
          end

          parent
        end

        create_graph(
          parent: group,
          children: evaluator.children,
          depth: evaluator.depth
        )
      end
    end

    trait :crm_disabled do
      after(:create) do |group|
        create(:crm_settings, group: group, enabled: false)
      end
    end

    trait :with_root_storage_statistics do
      association :root_storage_statistics, factory: :namespace_root_storage_statistics
    end
  end
end
