# frozen_string_literal: true

class DeleteOrphanedDeployTokens < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.3'

  def up
    define_batchable_model(:deploy_tokens).where(project_id: nil, group_id: nil).each_batch do |batch|
      associated_projects = define_batchable_model(:project_deploy_tokens)
        .where('deploy_tokens.id = project_deploy_tokens.deploy_token_id')

      associated_groups = define_batchable_model(:group_deploy_tokens)
        .where('deploy_tokens.id = group_deploy_tokens.deploy_token_id')

      batch.where('NOT EXISTS (?) AND NOT EXISTS (?)', associated_projects, associated_groups).delete_all
    end
  end

  def down
    # No-op
  end
end
