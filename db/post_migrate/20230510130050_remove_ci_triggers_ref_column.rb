# frozen_string_literal: true

class RemoveCiTriggersRefColumn < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    remove_column :ci_triggers, :ref
  end

  def down
    add_column :ci_triggers, :ref, :string, if_not_exists: true
  end
end
