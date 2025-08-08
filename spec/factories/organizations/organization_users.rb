# frozen_string_literal: true

FactoryBot.define do
  factory :organization_user, class: 'Organizations::OrganizationUser' do
    # User factory is also creating organization_users record. We want to avoid that
    user { association(:user, organizations: []) }
    organization { association(:common_organization) }

    trait :without_common_organization do
      organization { association(:organization) }
    end

    trait :owner do
      access_level { Gitlab::Access::OWNER }
    end

    factory :organization_owner, traits: [:owner]
  end
end
