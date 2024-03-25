# frozen_string_literal: true

class MakeCandidateIdOnMlCandidateParamsNonNullable < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  disable_ddl_transaction!

  def up
    add_not_null_constraint :ml_candidate_params, :candidate_id
  end

  def down
    remove_not_null_constraint :ml_candidate_params, :candidate_id
  end
end
