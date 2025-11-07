# frozen_string_literal: true

class ValidateNotesShardingKeyNotNullConstraint < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    validate_check_constraint(:notes, 'check_82f260979e')
  end

  def down
    # no-op
  end
end
