# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillOrganizationIdKeys < BatchedMigrationJob
      operation_name :backfill_keys_organization_id
      feature_category :system_access

      def perform
        each_sub_batch do |sub_batch|
          backfill_organization_id(sub_batch)
        end
      end

      private

      def backfill_organization_id(keys_batch)
        ssh_keys = keys_batch.where(type: [nil, 'Key']).where.not(user_id: nil)
        backfill_ssh_keys(ssh_keys)

        deploy_keys = keys_batch.where(type: 'DeployKey')
        backfill_deploy_keys(deploy_keys)

        orphaned_deploy_keys = keys_batch
          .where(type: 'DeployKey')
          .where("NOT EXISTS (SELECT 1 FROM deploy_keys_projects WHERE deploy_keys_projects.deploy_key_id = keys.id)")

        backfill_orphaned_deploy_keys(orphaned_deploy_keys)
      end

      def backfill_ssh_keys(ssh_keys)
        connection.execute(<<~SQL)
          UPDATE keys
          SET organization_id = users.organization_id
          FROM users
          WHERE keys.user_id = users.id
          AND keys.organization_id IS NULL
          AND keys.id IN (#{ssh_keys.select(:id).to_sql})
        SQL
      end

      def backfill_deploy_keys(deploy_keys)
        connection.execute(<<~SQL)
          UPDATE keys
          SET organization_id = subquery.organization_id
          FROM (
            SELECT DISTINCT ON (keys.id) keys.id, projects.organization_id
            FROM keys
            INNER JOIN deploy_keys_projects ON deploy_keys_projects.deploy_key_id = keys.id
            INNER JOIN projects ON projects.id = deploy_keys_projects.project_id
            WHERE keys.id IN (#{deploy_keys.select(:id).to_sql})
              AND projects.organization_id IS NOT NULL
            ORDER BY keys.id, deploy_keys_projects.id
          ) AS subquery
          WHERE keys.id = subquery.id
            AND keys.organization_id IS NULL
        SQL
      end

      def backfill_orphaned_deploy_keys(orphaned_keys)
        # Orphaned deploy keys have no project association, so we assign them to the default organization.
        # This is acceptable in a one-time backfill migration as it only affects legacy orphaned records.
        orphaned_keys.where(organization_id: nil).update_all(
          organization_id: ::Organizations::Organization.first.id # rubocop:disable Gitlab/PreventOrganizationFirst -- Backfilling orphaned deploy keys to default organization
        )
      end
    end
  end
end
