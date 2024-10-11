# frozen_string_literal: true

FactoryBot.define do
  factory :protected_branch_push_access_level, class: 'ProtectedBranch::PushAccessLevel' do
    association :protected_branch, default_access_level: false
    deploy_key { nil }
    access_level { Gitlab::Access::DEVELOPER }

    trait :no_access do
      access_level { Gitlab::Access::NO_ACCESS }
    end

    trait :developer_access do
      access_level { Gitlab::Access::DEVELOPER }
    end

    trait :maintainer_access do
      access_level { Gitlab::Access::MAINTAINER }
    end
  end
end
