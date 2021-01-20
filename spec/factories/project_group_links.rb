# frozen_string_literal: true

FactoryBot.define do
  factory :project_group_link do
    project
    group { association(:group) }
    expires_at { nil }
    group_access { Gitlab::Access::DEVELOPER }

    trait(:guest) { group_access { Gitlab::Access::GUEST } }
    trait(:reporter) { group_access { Gitlab::Access::REPORTER } }
    trait(:developer) { group_access { Gitlab::Access::DEVELOPER } }
    trait(:maintainer) { group_access { Gitlab::Access::MAINTAINER } }

    after(:create) do |project_group_link, evaluator|
      project_group_link.group.refresh_members_authorized_projects
    end
  end
end
