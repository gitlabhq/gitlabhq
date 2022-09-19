# frozen_string_literal: true

class AddInternalToNotes < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column(:notes, :internal, :boolean, default: false, null: false)
  end
end
