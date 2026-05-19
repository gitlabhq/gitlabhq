# frozen_string_literal: true

class CleanupNullEndpointsOnAiSelfHostedModels < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_setting
  disable_ddl_transaction!

  PLACEHOLDER_ENDPOINT = 'http://selfhostedmodel.com'
  BATCH_SIZE = 1000

  class AiSelfHostedModel < MigrationRecord
    include EachBatch

    self.table_name = 'ai_self_hosted_models'
  end

  def up
    # no-op - this migration exists to allow rollback of
    # DropNotNullConstraintOnAiSelfHostedModelsEndpointColumn
  end

  def down
    # Backfill NULL endpoints with a placeholder so the NOT NULL constraint can be safely restored
    AiSelfHostedModel.each_batch(of: BATCH_SIZE) do |relation|
      relation.where(endpoint: nil).update_all(endpoint: PLACEHOLDER_ENDPOINT)
    end
  end
end
