# frozen_string_literal: true

FactoryBot.define do
  factory :group, class: 'Group', parent: :namespace do
    sequence(:name) { |n| "group#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    type { 'Group' }
    owner { nil }
    project_creation_level { ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS}

    after(:create) do |group|
      if group.owner
        # We could remove this after we have proper constraint:
        # https://gitlab.com/gitlab-org/gitlab-foss/issues/43292
        raise "Don't set owner for groups, use `group.add_owner(user)` instead"
      end
    end

    trait :public do
      visibility_level { Gitlab::VisibilityLevel::PUBLIC}
    end

    trait :internal do
      visibility_level {Gitlab::VisibilityLevel::INTERNAL}
    end

    trait :private do
      visibility_level { Gitlab::VisibilityLevel::PRIVATE}
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
      subgroup_creation_level { ::Gitlab::Access::OWNER_SUBGROUP_ACCESS}
    end
  end
end
