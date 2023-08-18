# frozen_string_literal: true

class EnsureBackfillForCiPipelineVariablesPipelineIdIsFinished < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipeline_variables

  def up
    # no-op
  end

  def down
    # no-op
  end
end
