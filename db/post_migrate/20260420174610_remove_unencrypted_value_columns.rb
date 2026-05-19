# frozen_string_literal: true

class RemoveUnencryptedValueColumns < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction! # Required because this migration touches multiple tables

  def up
    remove_column :ci_group_variables, :value
    remove_column :ci_pipeline_schedule_variables, :value
    remove_column :p_ci_pipeline_variables, :value
    remove_column :ci_variables, :value
  end

  def down
    add_column :ci_group_variables, :value, :text
    add_column :ci_pipeline_schedule_variables, :value, :text
    add_column :p_ci_pipeline_variables, :value, :text
    add_column :ci_variables, :value, :text
  end
end
