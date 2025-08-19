# frozen_string_literal: true

class AddModelPromptCacheEnabledToApplicationSettings < Gitlab::Database::Migration[2.3]
  # disable_ddl_transaction!

  milestone '18.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute <<~SQL
      UPDATE application_settings
      SET code_creation = COALESCE(code_creation, '{}'::jsonb) ||
      jsonb_build_object('model_prompt_cache_enabled',
        COALESCE(model_prompt_cache_enabled, true)
      )
    WHERE code_creation->>'model_prompt_cache_enabled' IS NULL
    SQL
  end

  def down
    execute <<~SQL
      UPDATE application_settings
      SET code_creation = code_creation - 'model_prompt_cache_enabled'
      WHERE code_creation ? 'model_prompt_cache_enabled'
    SQL
  end
end
