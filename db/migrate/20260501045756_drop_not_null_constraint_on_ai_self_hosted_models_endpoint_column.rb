# frozen_string_literal: true

class DropNotNullConstraintOnAiSelfHostedModelsEndpointColumn < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    change_column_null :ai_self_hosted_models, :endpoint, true
  end

  def down
    # Note: This may fail if there are NULL values in the column.
    # Make sure to rollback CleanupNullEndpointsOnAiSelfHostedModels before this migration.
    change_column_null :ai_self_hosted_models, :endpoint, false
  end
end
