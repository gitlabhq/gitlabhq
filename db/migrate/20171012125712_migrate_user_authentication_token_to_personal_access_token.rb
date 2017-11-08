# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateUserAuthenticationTokenToPersonalAccessToken < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # disable_ddl_transaction!

  TOKEN_NAME = 'Private Token'.freeze

  def up
    execute <<~SQL
      INSERT INTO personal_access_tokens (user_id, token, name, created_at, updated_at, scopes)
      SELECT id, authentication_token, '#{TOKEN_NAME}', NOW(), NOW(), '#{%w[api].to_yaml}'
      FROM users
      WHERE authentication_token IS NOT NULL
      AND admin = FALSE
      AND NOT EXISTS (
        SELECT true
        FROM personal_access_tokens
        WHERE user_id = users.id
        AND token = users.authentication_token
      )
    SQL

    # Admins also need the `sudo` scope
    execute <<~SQL
      INSERT INTO personal_access_tokens (user_id, token, name, created_at, updated_at, scopes)
      SELECT id, authentication_token, '#{TOKEN_NAME}', NOW(), NOW(), '#{%w[api sudo].to_yaml}'
      FROM users
      WHERE authentication_token IS NOT NULL
      AND admin = TRUE
      AND NOT EXISTS (
        SELECT true
        FROM personal_access_tokens
        WHERE user_id = users.id
        AND token = users.authentication_token
      )
    SQL
  end

  def down
    if Gitlab::Database.postgresql?
      execute <<~SQL
        UPDATE users
        SET authentication_token = pats.token
        FROM (
          SELECT user_id, token
          FROM personal_access_tokens
          WHERE name = '#{TOKEN_NAME}'
        ) AS pats
        WHERE id = pats.user_id
      SQL
    else
      execute <<~SQL
        UPDATE users
        INNER JOIN personal_access_tokens AS pats
        ON users.id = pats.user_id
        SET authentication_token = pats.token
        WHERE pats.name = '#{TOKEN_NAME}'
      SQL
    end

    execute <<~SQL
      DELETE FROM personal_access_tokens
      WHERE name = '#{TOKEN_NAME}'
      AND EXISTS (
        SELECT true
        FROM users
        WHERE id = personal_access_tokens.user_id
        AND authentication_token = personal_access_tokens.token
      )
    SQL
  end
end
