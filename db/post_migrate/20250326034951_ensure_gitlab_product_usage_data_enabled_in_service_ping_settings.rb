# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class EnsureGitlabProductUsageDataEnabledInServicePingSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.11'

  def up
    default_value = true

    execute <<~SQL
      UPDATE application_settings
      SET service_ping_settings =
        CASE
          WHEN snowplow_enabled = TRUE THEN
            COALESCE(service_ping_settings, '{}'::jsonb) ||
            jsonb_build_object('gitlab_product_usage_data_enabled', FALSE)
          ELSE
            COALESCE(service_ping_settings, '{}'::jsonb) ||
            jsonb_build_object('gitlab_product_usage_data_enabled', #{default_value})
        END
    SQL
  end

  def down
    # no-op
  end
end
