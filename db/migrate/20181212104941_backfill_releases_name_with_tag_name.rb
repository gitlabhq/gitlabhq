# frozen_string_literal: true

class BackfillReleasesNameWithTagName < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    update_column_in_batches(:releases, :name, Release.arel_table[:tag])
  end

  def down
    # no-op
  end
end
