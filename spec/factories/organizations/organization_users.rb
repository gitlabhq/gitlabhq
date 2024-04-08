# frozen_string_literal: true

FactoryBot.define do
  factory :organization_user, class: 'Organizations::OrganizationUser' do
    user
    organization

    trait :owner do
      access_level { Gitlab::Access::OWNER }
    end

    factory :organization_owner, traits: [:owner]
  end
end
