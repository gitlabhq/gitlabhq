# frozen_string_literal: true

class CleanupAppearancesShortTitleRename < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :appearances, :short_title, :pwa_short_name
  end

  def down
    undo_cleanup_concurrent_column_rename :appearances, :short_title, :pwa_short_name
  end
end
