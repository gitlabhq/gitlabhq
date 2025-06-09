# frozen_string_literal: true

class PopulateDefaultValueForPersonalAccessTokensPrefix < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_clusterwide_setting
  milestone '18.1'

  def up
    execute(
      <<-SQL
      UPDATE
        application_settings
      SET
        personal_access_token_prefix = DEFAULT
      WHERE
        personal_access_token_prefix IS NULL
      SQL
    )
  end

  def down
    # no-op
    # To reverse this migration, we would need to be able to determine if the setting was previously set to nil
  end
end
