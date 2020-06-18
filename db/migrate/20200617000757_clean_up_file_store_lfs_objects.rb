# frozen_string_literal: true

class CleanUpFileStoreLfsObjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/UpdateColumnInBatches
    update_column_in_batches(:lfs_objects, :file_store, 1) do |table, query|
      query.where(table[:file_store].eq(nil))
    end
    # rubocop:enable Migration/UpdateColumnInBatches
  end

  def down
    # no-op
  end
end
