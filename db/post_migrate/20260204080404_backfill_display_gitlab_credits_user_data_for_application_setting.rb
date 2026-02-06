# frozen_string_literal: true

class BackfillDisplayGitlabCreditsUserDataForApplicationSetting < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute <<~SQL
      UPDATE application_settings
      SET usage_billing = jsonb_set(COALESCE(usage_billing, '{}'), '{display_gitlab_credits_user_data}', 'true')
    SQL
  end

  def down
    execute <<~SQL
      UPDATE application_settings
      SET usage_billing = jsonb_set(COALESCE(usage_billing, '{}'), '{display_gitlab_credits_user_data}', 'false')
    SQL
  end
end
