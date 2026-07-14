# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    # Resolves the organization and username for the seeded administrator so the
    # admin fixtures work in a multi-cell cluster.
    #
    # On the cell that owns the default organization (the legacy cell, or any
    # single-cell installation) the admin reuses the default organization and the
    # `root` username. On every other cell the default organization is absent --
    # its cluster-wide claim is held elsewhere, see DefaultOrganizationImporter --
    # so a per-cell organization is created and a per-cell username is derived,
    # keeping the cluster-global ORGANIZATION_PATH and USERNAMES claims unique.
    #
    # NOTE: `organization_for_admin` is not idempotent -- when no default
    # organization exists it creates a new organization on every call (the derived
    # path includes a random suffix).
    module AdminOrganizationImporter
      DEFAULT_USERNAME = 'root'

      def self.organization_for_admin
        # rubocop:disable Gitlab/AvoidDefaultOrganization -- reuse the default org when present; else create one
        ::Organizations::Organization.default_organization || create_organization
        # rubocop:enable Gitlab/AvoidDefaultOrganization
      end

      def self.default_username_for(organization)
        return DEFAULT_USERNAME if organization.default?

        "#{DEFAULT_USERNAME}-#{cell_suffix}"
      end

      def self.create_organization
        suffix = cell_suffix

        ::Organizations::Organization.create!(
          name: ENV['GITLAB_ROOT_ORG_NAME'].presence || "Admin org #{suffix}",
          path: ENV['GITLAB_ROOT_ORG_PATH'].presence || "admin-org-#{suffix}",
          visibility_level: ::Organizations::Organization::PUBLIC,
          state: ::Organizations::Organization.states[:active]
        )
      end

      # A per-cell, cluster-unique suffix: the cell id keeps it legible in
      # multi-cell debugging, the random component guarantees uniqueness.
      def self.cell_suffix
        "cell-#{::Gitlab.config.cell.id}-#{SecureRandom.hex(4)}"
      end

      private_class_method :create_organization, :cell_suffix
    end
  end
end
