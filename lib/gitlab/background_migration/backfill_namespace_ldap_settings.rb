# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Back-fill container_registry_size for project_statistics
    class BackfillNamespaceLdapSettings < Gitlab::BackgroundMigration::BatchedMigrationJob
      operation_name :backfill_namespace_ldap_settings
      feature_category :authentication_and_authorization

      def perform
        # no-op in FOSS
      end
    end
  end
end

Gitlab::BackgroundMigration::BackfillNamespaceLdapSettings.prepend_mod
