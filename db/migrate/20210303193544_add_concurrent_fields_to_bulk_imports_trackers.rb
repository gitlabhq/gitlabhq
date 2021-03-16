# frozen_string_literal: true

class AddConcurrentFieldsToBulkImportsTrackers < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # rubocop:disable Rails/NotNullColumn
  def up
    add_column :bulk_import_trackers, :jid, :text
    add_column :bulk_import_trackers, :stage, :smallint, default: 0, null: false
    add_column :bulk_import_trackers, :status, :smallint, default: 0, null: false
  end
  # rubocop:enable Migration/AddLimitToTextColumns
  # rubocop:enable Rails/NotNullColumn

  def down
    remove_column :bulk_import_trackers, :jid, :text
    remove_column :bulk_import_trackers, :stage, :smallint
    remove_column :bulk_import_trackers, :status, :smallint
  end
end
