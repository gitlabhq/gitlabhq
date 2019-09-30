# frozen_string_literal: true

class BackfillReleasesTableUpdatedAtAndAddNotNullConstraintsToTimestamps < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    change_column_null(:releases, :created_at, false, Time.zone.now)

    update_column_in_batches(:releases, :updated_at, Arel.sql('created_at')) do |table, query|
      query.where(table[:updated_at].eq(nil))
    end

    change_column_null(:releases, :updated_at, false, Time.zone.now)
  end

  def down
    change_column_null(:releases, :updated_at, true)
    change_column_null(:releases, :created_at, true)
  end
end
