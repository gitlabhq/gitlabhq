# frozen_string_literal: true

class IncreaseSizeOnInstanceLevelVariableValues < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    existing_constraint_name = text_limit_name(:ci_instance_variables, :encrypted_value)
    new_constraint_name = check_constraint_name(:ci_instance_variables, :encrypted_value, :char_length_updated)

    add_text_limit(:ci_instance_variables, :encrypted_value, 13_579, constraint_name: new_constraint_name)
    remove_check_constraint(:ci_instance_variables, existing_constraint_name)
  end

  def down
    # no-op
  end
end
