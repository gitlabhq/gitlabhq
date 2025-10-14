# frozen_string_literal: true

class RemoveNotNullCiJobDefinitionsUpdatedAt < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def up
    change_column_null(:p_ci_job_definitions, :updated_at, true)
  end

  def down
    # no-op - as there would be data written (without updated_at) to the table after the constraint is removed
  end
end
