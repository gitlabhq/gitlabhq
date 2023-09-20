# frozen_string_literal: true

class AddSyncForeignKeyForCiPipelineVariablesPipelineId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_pipeline_variables
  COLUMN_NAME = :pipeline_id
  FK_NAME = :temp_fk_rails_8d3b04e3e1

  def up
    validate_foreign_key TABLE_NAME, COLUMN_NAME, name: FK_NAME
  end

  def down
    # no-op
  end
end
