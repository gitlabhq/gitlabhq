# frozen_string_literal: true

class AddLimitToAppereancesShortTitle < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_text_limit :appearances, :short_title, 255
  end

  def down
    remove_text_limit :appearances, :short_title
  end
end
