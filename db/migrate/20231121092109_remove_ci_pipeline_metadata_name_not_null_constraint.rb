# frozen_string_literal: true

class RemoveCiPipelineMetadataNameNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_25d23931f1'

  def up
    remove_not_null_constraint :ci_pipeline_metadata, :name, constraint_name: CONSTRAINT_NAME
  end

  def down
    add_not_null_constraint :ci_pipeline_metadata, :name, constraint_name: CONSTRAINT_NAME
  end
end
