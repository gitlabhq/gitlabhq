# frozen_string_literal: true

class AddPromptInjectionProtectionLevelToNamespaceAiSettings < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  INDEX_NAME = 'idx_namespace_ai_settings_on_prompt_injection_protection_level'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column(:namespace_ai_settings, :prompt_injection_protection_level,
        :integer, default: 0, null: false, limit: 2, if_not_exists: true)
    end

    add_concurrent_index(:namespace_ai_settings, [:prompt_injection_protection_level], name: INDEX_NAME)
  end

  def down
    with_lock_retries do
      remove_column(:namespace_ai_settings, :prompt_injection_protection_level, if_exists: true)
    end

    remove_concurrent_index_by_name(:namespace_ai_settings, INDEX_NAME)
  end
end
