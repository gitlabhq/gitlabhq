# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDesignManagementDesignsProjectNamespaceId < BatchedMigrationJob
      operation_name :backfill_design_management_designs_project_namespace_id
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          sub_batch_ids = sub_batch.select(:id)
          update_design_management_designs_namespace_id!(sub_batch_ids)

          # Since the design_management_designs table now has the correct namespace_id, we can now update the values on
          # the child tables (design_management_designs_versions and design_user_mentions)
          update_design_management_designs_versions_namespace_id!(sub_batch_ids)
          update_design_user_mentions_namespace_id!(sub_batch_ids)
        end
      end

      private

      # Sets the namespace_id on design_management_designs to the corresponding project's project_namespace_id
      def update_design_management_designs_namespace_id!(sub_batch_ids)
        sql = <<~SQL
          UPDATE design_management_designs
          SET namespace_id = p.project_namespace_id
          FROM projects p
          WHERE design_management_designs.project_id = p.id
          AND design_management_designs.id IN (#{sub_batch_ids.to_sql})
        SQL

        ApplicationRecord.connection.execute(sql)
      end

      # Sets the namespace_id on design_management_designs_versions to the corresponding design_management_designs's
      # namespace_id
      def update_design_management_designs_versions_namespace_id!(sub_batch_ids)
        sql = <<~SQL
          UPDATE design_management_designs_versions
          SET namespace_id = design_management_designs.namespace_id
          FROM design_management_designs
          WHERE design_management_designs.id = design_management_designs_versions.design_id
          AND design_management_designs_versions.design_id IN (#{sub_batch_ids.to_sql})
        SQL

        ApplicationRecord.connection.execute(sql)
      end

      # Sets the namespace_id on design_user_mentions to the corresponding design_management_designs's namespace_id
      def update_design_user_mentions_namespace_id!(sub_batch_ids)
        sql = <<~SQL
          UPDATE design_user_mentions
          SET namespace_id = design_management_designs.namespace_id
          FROM design_management_designs
          WHERE design_management_designs.id = design_user_mentions.design_id
          AND design_user_mentions.design_id IN (#{sub_batch_ids.to_sql})
        SQL

        ApplicationRecord.connection.execute(sql)
      end
    end
  end
end
