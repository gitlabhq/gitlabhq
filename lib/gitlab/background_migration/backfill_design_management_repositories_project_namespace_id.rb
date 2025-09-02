# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDesignManagementRepositoriesProjectNamespaceId < BatchedMigrationJob
      operation_name :backfill_design_management_repositories_project_namespace_id
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          sub_batch_ids = sub_batch.select(:id)
          update_design_management_repositories_namespace_id!(sub_batch_ids)

          # Since the design_management_repositories table now has the correct namespace_id, we can now update the
          # values on the child table (design_management_repository_states)
          update_design_management_repository_states_namespace_id!(sub_batch_ids)
        end
      end

      private

      # Sets the namespace_id on design_management_repositories to the corresponding project's project_namespace_id
      def update_design_management_repositories_namespace_id!(sub_batch_ids)
        sql = <<~SQL
          UPDATE design_management_repositories
          SET namespace_id = p.project_namespace_id
          FROM projects p
          WHERE design_management_repositories.project_id = p.id
          AND design_management_repositories.id IN (#{sub_batch_ids.to_sql})
        SQL

        ApplicationRecord.connection.execute(sql)
      end

      # Sets the namespace_id on design_management_repository_states to the corresponding
      # design_management_repositories's namespace_id
      def update_design_management_repository_states_namespace_id!(sub_batch_ids)
        sql = <<~SQL
          UPDATE design_management_repository_states
          SET namespace_id = design_management_repositories.namespace_id
          FROM design_management_repositories
          WHERE design_management_repositories.id = design_management_repository_states.design_management_repository_id
          AND design_management_repository_states.design_management_repository_id IN (#{sub_batch_ids.to_sql})
        SQL

        ApplicationRecord.connection.execute(sql)
      end
    end
  end
end
