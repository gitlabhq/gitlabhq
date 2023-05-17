# frozen_string_literal: true

class RemoveCiTriggersRefColumn < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    remove_column :ci_triggers, :ref
  end

  def down
    # rubocop:disable Migration/SchemaAdditionMethodsNoPost
    add_column :ci_triggers, :ref, :string, if_not_exists: true
    # rubocop:enable Migration/SchemaAdditionMethodsNoPost
  end
end
