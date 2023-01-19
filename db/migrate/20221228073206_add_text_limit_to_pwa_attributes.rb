# frozen_string_literal: true

class AddTextLimitToPwaAttributes < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :appearances, :pwa_name, 255
    add_text_limit :appearances, :pwa_description, 2048
  end

  def down
    remove_text_limit :appearances, :pwa_name
    remove_text_limit :appearances, :pwa_description
  end
end
