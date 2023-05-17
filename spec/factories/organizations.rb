# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Organization ##{n}" }

    trait :default do
      id { Organization::DEFAULT_ORGANIZATION_ID }
      name { 'Default' }
      initialize_with do
        # Ensure we only use one default organization
        Organization.find_by(id: Organization::DEFAULT_ORGANIZATION_ID) || new(**attributes)
      end
    end
  end
end
