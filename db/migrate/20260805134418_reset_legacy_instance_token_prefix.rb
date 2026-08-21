# frozen_string_literal: true

class ResetLegacyInstanceTokenPrefix < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  # 'gl' was the instance_token_prefix default until 2025-05-11 and is still persisted on
  # instances that saved settings then. Reset it to '' so the feature never prepends "gl-".
  LEGACY_DEFAULT_PREFIX = 'gl'

  def up
    execute <<~SQL
      UPDATE application_settings
      SET token_prefixes = jsonb_set(token_prefixes, '{instance_token_prefix}', '""')
      WHERE token_prefixes->>'instance_token_prefix' = #{connection.quote(LEGACY_DEFAULT_PREFIX)}
    SQL
  end

  def down
    # no-op: rows reset in this migration are indistinguishable from rows a user intentionally
    # left empty, and the legacy 'gl' default must not be restored.
  end
end
