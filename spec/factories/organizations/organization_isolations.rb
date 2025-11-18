# frozen_string_literal: true

FactoryBot.define do
  factory :organization_isolation, class: 'Organizations::OrganizationIsolation' do
    organization { association(:organization) }
    isolated { false }

    trait :isolated do
      isolated { true }
    end

    trait :not_isolated do
      isolated { false }
    end
  end
end
