# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class is used to update the delayed_project_removal column
    # for user namespaces of the namespace_settings table.
    class UpdateDelayedProjectRemovalToNullForUserNamespaces < Gitlab::BackgroundMigration::BatchedMigrationJob
      # Migration only version of `namespace_settings` table
      class NamespaceSetting < ::ApplicationRecord
        self.table_name = 'namespace_settings'
      end

      operation_name :set_delayed_project_removal_to_null_for_user_namespace
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          set_delayed_project_removal_to_null_for_user_namespace(sub_batch)
        end
      end

      private

      def set_delayed_project_removal_to_null_for_user_namespace(relation)
        NamespaceSetting.connection.execute(
          <<~SQL
            UPDATE namespace_settings
            SET delayed_project_removal = NULL
            WHERE
              namespace_settings.namespace_id IN (
                SELECT
                  namespace_settings.namespace_id
                FROM
                  namespace_settings
                  INNER JOIN namespaces ON namespaces.id = namespace_settings.namespace_id
                WHERE
                  namespaces.id IN (#{relation.select(:namespace_id).to_sql})
                  AND namespaces.type = 'User'
                  AND namespace_settings.delayed_project_removal = FALSE)
        SQL
        )
      end
    end
  end
end
