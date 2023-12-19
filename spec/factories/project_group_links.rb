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
    trait(:owner) { group_access { Gitlab::Access::OWNER } }

    after(:create) do |project_group_link|
      project_group_link.run_after_commit_or_now do
        AuthorizedProjectUpdate::ProjectRecalculateService.new(project_group_link.project).execute
      end
    end
  end
end
