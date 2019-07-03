# frozen_string_literal: true

class BackfillAndAddNotNullConstraintToReleasedAtColumnOnReleasesTable < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    update_column_in_batches(:releases, :released_at, Arel.sql('created_at'))
    change_column_null(:releases, :released_at, false)
  end

  def down
    change_column_null(:releases, :released_at, true)
  end
end
