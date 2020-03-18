# frozen_string_literal: true

class AddVariableTypeToCiPipelineVariables < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false
  ENV_VAR_VARIABLE_TYPE = 1

  # rubocop:disable Migration/AddColumnWithDefault
  # rubocop:disable Migration/UpdateLargeTable
  def up
    add_column_with_default(:ci_pipeline_variables, :variable_type, :smallint, default: ENV_VAR_VARIABLE_TYPE)
  end
  # rubocop:enable Migration/AddColumnWithDefault
  # rubocop:enable Migration/UpdateLargeTable

  def down
    remove_column(:ci_pipeline_variables, :variable_type)
  end
end
