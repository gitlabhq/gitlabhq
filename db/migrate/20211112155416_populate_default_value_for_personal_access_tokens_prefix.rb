# frozen_string_literal: true

class PopulateDefaultValueForPersonalAccessTokensPrefix < Gitlab::Database::Migration[1.0]
  def up
    execute(
      <<-SQL
      UPDATE
        application_settings
      SET
        personal_access_token_prefix = default
      WHERE
        personal_access_token_prefix IS NULL
      SQL
    )
  end

  def down
    # no-op
  end
end
