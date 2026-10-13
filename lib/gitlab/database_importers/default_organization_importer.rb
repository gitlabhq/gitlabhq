# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module DefaultOrganizationImporter
      # Mirrors LegacyCellId in the Topology Service, which reserves the IDs below 10^12,
      # including DEFAULT_ORGANIZATION_ID, for the legacy cell.
      LEGACY_CELL_ID = 1

      def self.create_default_organization
        return if ::Organizations::Organization.default_organization

        unless owns_default_organization?
          ::Gitlab::AppLogger.info(
            message: 'Skipping default organization creation, it belongs to the legacy cell',
            Labkit::Fields::CLASS_NAME => name,
            cell_id: ::Gitlab.config.cell.id
          )

          return
        end

        # When adding or changing attributes, consider changing the factory for Organization model as well
        # spec/factories/organizations/organizations.rb
        #
        # The default organization is created as active because it predates the
        # unconfirmed/confirmed lifecycle and has no confirmed_by_user_id.
        ::Organizations::Organization.create!(
          id: ::Organizations::Organization::DEFAULT_ORGANIZATION_ID,
          name: ENV['GITLAB_ROOT_ORG_NAME'].presence || 'Default',
          path: ENV['GITLAB_ROOT_ORG_PATH'].presence || 'default',
          visibility_level: ::Organizations::Organization::PUBLIC,
          state: ::Organizations::Organization.states[:active]
        )
      end

      def self.owns_default_organization?
        !::Gitlab.config.cell.enabled || ::Gitlab.config.cell.id.to_i == LEGACY_CELL_ID
      end

      private_class_method :owns_default_organization?
    end
  end
end
