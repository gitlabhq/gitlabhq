# frozen_string_literal: true

class CleanUpStoreUploads < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/UpdateColumnInBatches
    update_column_in_batches(:uploads, :store, 1) do |table, query|
      query.where(table[:store].eq(nil))
    end
    # rubocop:enable Migration/UpdateColumnInBatches
  end

  def down
    # no-op
  end
end
