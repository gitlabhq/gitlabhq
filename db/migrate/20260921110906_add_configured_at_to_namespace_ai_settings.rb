# frozen_string_literal: true

class AddConfiguredAtToNamespaceAiSettings < Gitlab::Database::Migration[2.3]
  milestone '19.5'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_namespace_ai_settings_configured_at_is_hash'

  def up
    with_lock_retries do
      add_column :namespace_ai_settings, :configured_at, :jsonb, default: {}, null: false, if_not_exists: true
    end

    add_check_constraint(
      :namespace_ai_settings,
      "(jsonb_typeof(configured_at) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :namespace_ai_settings, CONSTRAINT_NAME

    with_lock_retries do
      remove_column :namespace_ai_settings, :configured_at, if_exists: true
    end
  end
end
