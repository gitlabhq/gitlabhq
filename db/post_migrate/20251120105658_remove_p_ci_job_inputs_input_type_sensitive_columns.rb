# frozen_string_literal: true

class RemovePCiJobInputsInputTypeSensitiveColumns < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def up
    remove_column :p_ci_job_inputs, :input_type
    remove_column :p_ci_job_inputs, :sensitive
  end

  def down
    add_column :p_ci_job_inputs, :input_type, :integer, default: 0, null: false, limit: 2
    add_column :p_ci_job_inputs, :sensitive, :boolean, default: false, null: false
  end
end
