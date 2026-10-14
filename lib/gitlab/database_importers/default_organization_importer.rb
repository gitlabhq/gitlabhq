# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module DefaultOrganizationImporter
      def self.create_default_organization
        return if ::Organizations::Organization.default_organization

        unless owns_default_organization?
          ::Gitlab::AppLogger.info(
            message: 'Skipping default organization creation, its ID is outside the cell sequence ranges',
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

      # The Topology Service gives only one cell a sequence range that covers DEFAULT_ORGANIZATION_ID.
      def self.owns_default_organization?
        return true unless ::Current.cells_claims_leases?

        ::Gitlab::TopologyServiceClient::CellService.new.cell_sequence_ranges.to_a.any? do |range|
          (range.minval..range.maxval).cover?(::Organizations::Organization::DEFAULT_ORGANIZATION_ID)
        end
      end

      private_class_method :owns_default_organization?
    end
  end
end
