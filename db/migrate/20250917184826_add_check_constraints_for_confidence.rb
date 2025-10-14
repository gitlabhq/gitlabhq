# frozen_string_literal: true

class AddCheckConstraintsForConfidence < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  TABLE = :vulnerability_flags

  def constraint_name
    check_constraint_name TABLE, :confidence_score, "between_0_and_1"
  end

  def up
    add_check_constraint TABLE, 'confidence_score >= 0 AND confidence_score <= 1', constraint_name
  end

  def down
    remove_check_constraint TABLE, constraint_name
  end
end
