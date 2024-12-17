# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module DefaultOrganizationImporter
      def self.create_default_organization
        return if ::Organizations::Organization.default_organization

        # When adding or changing attributes, consider changing the factory for Organization model as well
        # spec/factories/organizations/organizations.rb
        ::Organizations::Organization.create!(
          id: ::Organizations::Organization::DEFAULT_ORGANIZATION_ID,
          name: 'Default',
          path: 'default',
          visibility_level: ::Organizations::Organization::PUBLIC
        )
      end
    end
  end
end
