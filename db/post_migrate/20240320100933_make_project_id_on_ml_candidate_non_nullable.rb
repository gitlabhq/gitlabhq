# frozen_string_literal: true

class MakeProjectIdOnMlCandidateNonNullable < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  disable_ddl_transaction!

  def up
    # This will add the `NOT NULL` constraint and validate it
    add_not_null_constraint :ml_candidates, :project_id
  end

  def down
    # Down is required as `add_not_null_constraint` is not reversible
    remove_not_null_constraint :ml_candidates, :project_id
  end
end
