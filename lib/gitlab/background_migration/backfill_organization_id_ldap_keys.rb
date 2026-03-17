# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillOrganizationIdLdapKeys < BatchedMigrationJob
      operation_name :backfill_organization_id_ldap_keys
      feature_category :system_access

      # rubocop:disable Database/AvoidScopeTo -- supporting index: index_keys_on_id_and_ldap_key_type
      scope_to ->(relation) { relation.where(type: 'LDAPKey') }
      # rubocop:enable Database/AvoidScopeTo

      def perform
        # Resolve default organization ID once, outside the sub-batch loop, to avoid
        # a redundant SELECT query on every sub-batch iteration.
        # rubocop:disable Gitlab/PreventOrganizationFirst -- Backfilling LDAP keys to default organization
        default_organization_id = ::Organizations::Organization.first.id
        # rubocop:enable Gitlab/PreventOrganizationFirst

        each_sub_batch do |sub_batch|
          backfill_organization_id(sub_batch, default_organization_id)
        end
      end

      private

      def backfill_organization_id(keys_batch, default_organization_id)
        backfill_ldap_keys_with_user(keys_batch)
        backfill_orphaned_ldap_keys(keys_batch, default_organization_id)
        backfill_remaining_ldap_keys(keys_batch, default_organization_id)
      end

      def backfill_ldap_keys_with_user(ldap_keys)
        connection.execute(<<~SQL)
          UPDATE keys
          SET organization_id = users.organization_id
          FROM users
          WHERE keys.user_id = users.id
          AND keys.organization_id IS NULL
          AND keys.id IN (#{ldap_keys.select(:id).to_sql})
        SQL
      end

      def backfill_orphaned_ldap_keys(ldap_keys, default_organization_id)
        # Orphaned LDAP keys have no user association. This should not happen in practice
        # (all LDAPKeys are created via LDAP sync with a user), but we handle it defensively
        # since self-managed databases may have unexpected data.
        ldap_keys.where(user_id: nil).where(organization_id: nil).update_all(
          organization_id: default_organization_id
        )
      end

      def backfill_remaining_ldap_keys(ldap_keys, default_organization_id)
        # Catch-all for any LDAPKeys still without organization_id after the above steps.
        # This handles edge cases like user_id pointing to a deleted user row (JOIN won't match,
        # but user_id IS NOT NULL so the orphan handler also won't match).
        ldap_keys.where(organization_id: nil).update_all(
          organization_id: default_organization_id
        )
      end
    end
  end
end
