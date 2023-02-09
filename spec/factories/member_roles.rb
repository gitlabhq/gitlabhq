# frozen_string_literal: true

FactoryBot.define do
  factory :member_role do
    namespace { association(:group) }
    base_access_level { Gitlab::Access::DEVELOPER }

    trait(:developer) { base_access_level { Gitlab::Access::DEVELOPER } }
    trait(:guest) { base_access_level { Gitlab::Access::GUEST } }
  end
end
