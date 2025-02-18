# frozen_string_literal: true

# When adding or changing attributes, consider changing the database importer as well
# lib/gitlab/database_importers/default_organization_importer.rb
FactoryBot.define do
  factory :organization, class: 'Organizations::Organization' do
    sequence(:name) { |n| "Organization ##{n}" }
    path { name.parameterize }
    visibility_level { Organizations::Organization::PUBLIC }

    # The default organization ID is for specs that specifically target the default organization.
    # Most specs should just create a normal organization.
    trait :default do
      id { Organizations::Organization::DEFAULT_ORGANIZATION_ID }
      name { 'Default' }
      visibility_level { Organizations::Organization::PUBLIC }

      initialize_with do
        # Ensure we only use one default organization
        default_org = Organizations::Organization
          .where(id: Organizations::Organization::DEFAULT_ORGANIZATION_ID)
          .first_or_initialize
        default_org.attributes = attributes.except(:id)
        default_org
      end
    end

    trait :public do
      visibility_level { Organizations::Organization::PUBLIC }
    end

    trait :private do
      visibility_level { Organizations::Organization::PRIVATE }
    end
  end
end
