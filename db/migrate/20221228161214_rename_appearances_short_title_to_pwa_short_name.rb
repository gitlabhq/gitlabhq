# frozen_string_literal: true

class RenameAppearancesShortTitleToPwaShortName < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    rename_column_concurrently :appearances, :short_title, :pwa_short_name
  end

  def down
    undo_rename_column_concurrently :appearances, :short_title, :pwa_short_name
  end
end
