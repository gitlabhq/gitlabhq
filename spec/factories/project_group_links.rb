# frozen_string_literal: true

FactoryBot.define do
  factory :project_group_link do
    project
    group
    expires_at { nil }

    trait(:guest) { group_access { Gitlab::Access::GUEST } }
    trait(:reporter) { group_access { Gitlab::Access::REPORTER } }
    trait(:developer) { group_access { Gitlab::Access::DEVELOPER } }
    trait(:maintainer) { group_access { Gitlab::Access::MAINTAINER } }
  end
end
