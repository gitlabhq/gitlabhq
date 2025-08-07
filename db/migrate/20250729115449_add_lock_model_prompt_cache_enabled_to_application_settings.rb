# frozen_string_literal: true

class AddLockModelPromptCacheEnabledToApplicationSettings < Gitlab::Database::Migration[2.3]
  # disable_ddl_transaction!
  #
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '18.3'

  def up
    execute <<~SQL
      UPDATE application_settings
      SET code_creation = COALESCE(code_creation, '{}'::jsonb) ||
      jsonb_build_object('lock_model_prompt_cache_enabled',
        COALESCE(lock_model_prompt_cache_enabled, false)
      )
    WHERE code_creation->>'model_prompt_cache_enabled' IS NULL
    SQL
  end

  def down
    execute <<~SQL
      UPDATE application_settings
      SET code_creation = code_creation - 'lock_model_prompt_cache_enabled'
      WHERE code_creation ? 'lock_model_prompt_cache_enabled'
    SQL
  end
end
