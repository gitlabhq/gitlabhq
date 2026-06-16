# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module DefaultOrganizationImporter
      def self.create_default_organization
        return if ::Organizations::Organization.default_organization

        # When adding or changing attributes, consider changing the factory for Organization model as well
        # spec/factories/organizations/organizations.rb
        #
        # The default organization is created as active because it predates the
        # unconfirmed/confirmed lifecycle and has no confirmed_by_user_id.
        ::Organizations::Organization.create!(
          id: ::Organizations::Organization::DEFAULT_ORGANIZATION_ID,
          name: 'Default',
          path: 'default',
          visibility_level: ::Organizations::Organization::PUBLIC,
          state: ::Organizations::Organization.states[:active]
        )
      rescue ::Cells::TransactionRecord::AlreadyClaimedError
        # In a multi-cell cluster the organization `path` is a cluster-wide claim
        # (Organizations::Organization includes Cells::Claimable). The default
        # organization can only be claimed by a single cell, so on every other cell
        # the claim is already taken and creation must be skipped. Other lease
        # failures raise Cells::TransactionRecord::Error and propagate, so
        # provisioning is not silently skipped on the cell that should own it.
        ::Gitlab::AppLogger.info(
          message: 'Default organization path is already claimed by another cell; skipping creation',
          organization_path: 'default'
        )

        nil
      end
    end
  end
end
