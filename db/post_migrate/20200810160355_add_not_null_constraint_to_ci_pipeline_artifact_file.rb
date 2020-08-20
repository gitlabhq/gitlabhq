# frozen_string_literal: true

class AddNotNullConstraintToCiPipelineArtifactFile < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_not_null_constraint :ci_pipeline_artifacts, :file, validate: true
  end

  def down
    remove_not_null_constraint :ci_pipeline_artifacts, :file
  end
end
