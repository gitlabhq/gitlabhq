# frozen_string_literal: true

module Integrations
  module JiraForge
    # Finds the Jira installation for a verified FIT within an organization, or
    # creates a native Forge installation when none exists. Used by the Forge
    # first-link flow, where the organization is resolved from the linked
    # namespace -- the earliest point the correct organization is known.
    #
    # The apiBaseUrl + app system token ride the FIT-authenticated link call, so
    # they are stored here and the installation is forge_direct? immediately.
    # Keyed by the Forge installation id (unique per app install); an upgraded
    # Connect row is found by its site (cloud_id) and adopts the id.
    class FindOrCreateInstallationService
      def self.execute(**args)
        new(**args).execute
      end

      def initialize(installation_id:, cloud_id:, organization_id:, jira_api_base_url:, forge_system_token:)
        @installation_id = installation_id
        @cloud_id = cloud_id
        @organization_id = organization_id
        @forge_attrs = { jira_api_base_url: jira_api_base_url, forge_system_token: forge_system_token }
      end

      # Returns the installation; a failed refresh or create leaves its errors on
      # the returned record, so callers check `errors` rather than `persisted?`.
      def execute
        installation = find_installation

        if installation
          # Upgrade path: an existing (Connect) install adopts the Forge system
          # token; its Connect fields and subscriptions are kept.
          installation.update(forge_attrs)
          installation
        else
          create_installation
        end
      end

      private

      attr_reader :installation_id, :cloud_id, :organization_id, :forge_attrs

      def find_installation
        JiraConnectInstallation.find_or_backfill_by_forge_token(
          installation_id: installation_id, cloud_id: cloud_id, organization_id: organization_id
        )
      end

      # Fresh native install on the resolved organization. The global unique
      # index on the installation id is the only ownership check: a concurrent
      # first link in this organization is adopted, a row held by another
      # organization is refused without saying where it lives.
      def create_installation
        installation = JiraConnectInstallation.create(
          { organization_id: organization_id, cloud_id: cloud_id,
            forge_installation_xid: installation_id }.merge(forge_attrs)
        )
        return installation unless installation.errors.of_kind?(:forge_installation_xid, :taken)

        link_refusal
      rescue ActiveRecord::RecordNotUnique
        find_installation.tap { |installation| installation&.update(forge_attrs) } || link_refusal
      end

      def link_refusal
        Gitlab::AppLogger.info(
          message: 'Refused a Forge first link: the installation id is held outside this organization',
          forge_installation_xid: installation_id, Labkit::Fields::GL_ORGANIZATION_ID => organization_id
        )

        JiraConnectInstallation.new.tap do |unsaved|
          unsaved.errors.add(:base, s_('JiraConnect|This group cannot be linked to this Jira site.'))
        end
      end
    end
  end
end
