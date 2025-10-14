# frozen_string_literal: true

class ReintroduceShardingKeyNotNullConstraintNotValidOnNotes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    # no-op
    # This was causing some errors in old notes records that were getting updated
    # without using activerecord callbacks
  end

  def down
    # no-op
  end
end
