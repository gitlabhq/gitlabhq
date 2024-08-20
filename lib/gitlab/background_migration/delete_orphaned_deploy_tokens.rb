# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeleteOrphanedDeployTokens < BatchedMigrationJob
      operation_name :delete_orphaned_deploy_tokens
      feature_category :continuous_delivery

      def perform
        each_sub_batch do |sub_batch|
          associated_projects = define_batchable_model(:project_deploy_tokens, connection: sub_batch.connection)
            .where('deploy_tokens.id = project_deploy_tokens.deploy_token_id')

          associated_groups = define_batchable_model(:group_deploy_tokens, connection: sub_batch.connection)
            .where('deploy_tokens.id = group_deploy_tokens.deploy_token_id')

          sub_batch.where('NOT EXISTS (?) AND NOT EXISTS (?)', associated_projects, associated_groups).delete_all
        end
      end
    end
  end
end
