# frozen_string_literal: true

class AddFilterToWebHooks < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :web_hooks, :filter, :jsonb, null: false, default: {}, if_not_exists: true
    end
  end

  def down
    with_lock_retries do
      remove_column :web_hooks, :filter, if_exists: true
    end
  end
end
