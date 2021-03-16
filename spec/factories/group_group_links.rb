# frozen_string_literal: true

FactoryBot.define do
  factory :group_group_link do
    shared_group { association(:group) }
    shared_with_group { association(:group) }
    group_access { Gitlab::Access::DEVELOPER }

    trait(:guest) { group_access { Gitlab::Access::GUEST } }
    trait(:reporter) { group_access { Gitlab::Access::REPORTER } }
    trait(:developer) { group_access { Gitlab::Access::DEVELOPER } }
    trait(:owner) { group_access { Gitlab::Access::OWNER } }
    trait(:maintainer) { group_access { Gitlab::Access::MAINTAINER } }
  end
end
