# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDisplayGitlabCreditsUserDataForNamespaceSetting < BatchedMigrationJob
      operation_name :update_all
      feature_category :consumables_cost_management

      class NamespaceSetting < ::ApplicationRecord
        self.table_name = 'namespace_settings'
      end

      def perform
        each_sub_batch do |sub_batch|
          update_namespace_settings(sub_batch)
        end
      end

      private

      def update_namespace_settings(relation)
        NamespaceSetting.connection.execute(
          <<~SQL
            UPDATE namespace_settings
            SET usage_billing = jsonb_set(COALESCE(usage_billing, '{}'), '{display_gitlab_credits_user_data}', 'true')
            WHERE namespace_settings.namespace_id IN (
              SELECT namespace_settings.namespace_id
              FROM namespace_settings
              INNER JOIN namespaces ON namespaces.id = namespace_settings.namespace_id
              WHERE namespaces.id IN (#{relation.select(:namespace_id).to_sql})
                AND namespaces.type = 'Group'
            )
            AND (
              usage_billing IS NULL
              OR usage_billing ->> 'display_gitlab_credits_user_data' IS DISTINCT FROM 'true'
            )
          SQL
        )
      end
    end
  end
end
