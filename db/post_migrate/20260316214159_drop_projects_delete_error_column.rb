# frozen_string_literal: true

class DropProjectsDeleteErrorColumn < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    remove_column :projects, :delete_error, if_exists: true
  end

  def down
    add_column :projects, :delete_error, :text, if_not_exists: true
  end
end
