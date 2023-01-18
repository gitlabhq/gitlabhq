# frozen_string_literal: true

class AddTextLimitToPwaIcon < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :appearances, :pwa_icon, 1024
  end

  def down
    remove_text_limit :appearances, :pwa_icon
  end
end
