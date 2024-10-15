# frozen_string_literal: true

FactoryBot.define do
  factory :protected_tag_create_access_level, class: 'ProtectedTag::CreateAccessLevel' do
    deploy_key { nil }
    association :protected_tag, default_access_level: false
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
