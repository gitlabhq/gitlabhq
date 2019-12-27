# frozen_string_literal: true

class AddVariableTypeToCiVariables < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false
  ENV_VAR_VARIABLE_TYPE = 1

  def up
    add_column_with_default(:ci_variables, :variable_type, :smallint, default: ENV_VAR_VARIABLE_TYPE) # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:ci_variables, :variable_type)
  end
end
