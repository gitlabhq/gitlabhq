# frozen_string_literal: true

class SetShardingKeyForDeployTokensStaging < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '18.5'

  def up
    return unless Gitlab.staging?

    define_batchable_model(:deploy_tokens).where(project_id: nil, group_id: nil).each_batch do |batch|
      batch
        .where('project_deploy_tokens.deploy_token_id = deploy_tokens.id')
        .where(deploy_tokens: { project_id: nil })
        .update_all('project_id = project_deploy_tokens.project_id FROM project_deploy_tokens')
    end
  end

  def down
    # No-op
  end
end
