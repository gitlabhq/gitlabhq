# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDeployTokensShardingKey < BatchedMigrationJob
      operation_name :backfill_deploy_tokens_sharding_keys
      feature_category :continuous_delivery

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where('project_deploy_tokens.deploy_token_id = deploy_tokens.id')
            .where(deploy_tokens: { project_id: nil })
            .update_all('project_id = project_deploy_tokens.project_id FROM project_deploy_tokens')

          sub_batch
            .where('group_deploy_tokens.deploy_token_id = deploy_tokens.id')
            .where(deploy_tokens: { group_id: nil })
            .update_all('group_id = group_deploy_tokens.group_id FROM group_deploy_tokens')
        end
      end
    end
  end
end
