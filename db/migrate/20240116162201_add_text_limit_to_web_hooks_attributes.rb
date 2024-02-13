# frozen_string_literal: true

class AddTextLimitToWebHooksAttributes < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  disable_ddl_transaction!

  def up
    add_text_limit :web_hooks, :name, 255
    add_text_limit :web_hooks, :description, 2048
  end

  def down
    remove_text_limit :web_hooks, :name
    remove_text_limit :web_hooks, :description
  end
end
