# frozen_string_literal: true

class AddNamespaceIdToNotes < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    add_column :notes, :namespace_id, :bigint
  end

  def down
    remove_column :notes, :namespace_id
  end
end
