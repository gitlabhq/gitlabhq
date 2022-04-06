# frozen_string_literal: true

class AddOnHoldUntilColumnForBatchedMigration < Gitlab::Database::Migration[1.0]
  def change
    add_column :batched_background_migrations, :on_hold_until, :timestamptz,
      comment: 'execution of this migration is on hold until this time'
  end
end
