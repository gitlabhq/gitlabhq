# frozen_string_literal: true

class MigrateAnonymousSearchesFlagToApplicationSettingsV2 < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.1'

  def up
    # rubocop:disable Gitlab/FeatureFlagWithoutActor -- Does not execute in user context
    anonymous_searches_allowed = Feature.enabled?(:allow_anonymous_searches) # rubocop:disable Migration/PreventFeatureFlagsUsage -- helper is buggy right now will be fixed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190841
    # rubocop:enable Gitlab/FeatureFlagWithoutActor

    sql = <<~SQL
      UPDATE application_settings
      SET search = jsonb_set(
        COALESCE(search, '{}'::jsonb),
        '{anonymous_searches_allowed}',
        to_jsonb(#{anonymous_searches_allowed})
      ),
      updated_at = NOW()
      WHERE id = (SELECT MAX(id) FROM application_settings)
    SQL

    execute(sql)
  end

  def down
    sql = <<~SQL
      UPDATE application_settings
      SET search = search - 'anonymous_searches_allowed',
      updated_at = NOW()
      WHERE id = (SELECT MAX(id) FROM application_settings)
    SQL

    execute(sql)
  end
end
