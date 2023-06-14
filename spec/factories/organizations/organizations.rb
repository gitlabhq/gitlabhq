# frozen_string_literal: true

# When adding or changing attributes, consider changing the database importer as well
# lib/gitlab/database_importers/default_organization_importer.rb
FactoryBot.define do
  factory :organization, class: 'Organizations::Organization' do
    sequence(:name) { |n| "Organization ##{n}" }
    path { name.parameterize }

    trait :default do
      id { Organizations::Organization::DEFAULT_ORGANIZATION_ID }
      name { 'Default' }
      initialize_with do
        # Ensure we only use one default organization
        default_org = Organizations::Organization
          .where(id: Organizations::Organization::DEFAULT_ORGANIZATION_ID)
          .first_or_initialize
        default_org.attributes = attributes.except(:id)
        default_org
      end
    end
  end
end
