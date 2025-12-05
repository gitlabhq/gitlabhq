# frozen_string_literal: true

class EnableAuthnCleanupForGitlabCom < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return unless Gitlab.com_except_jh?

    execute <<~SQL
      UPDATE application_settings
      SET resource_access_tokens_settings = jsonb_set(
        COALESCE(resource_access_tokens_settings, '{}'::jsonb),
        '{authn_data_retention_cleanup_enabled}',
        'true'::jsonb
      )
    SQL
  end

  def down
    # no-op
  end
end
