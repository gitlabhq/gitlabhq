# frozen_string_literal: true

class AddCheckConstraintsToCiJobAnnotations < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_check_constraint(
      :p_ci_job_annotations,
      "(jsonb_typeof(data) = 'array')",
      'data_is_array'
    )
  end

  def down
    remove_check_constraint :p_ci_job_annotations, 'data_is_array'
  end
end
