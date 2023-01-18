# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveAtlassianRefreshTokenConstraint < Gitlab::Database::Migration[2.1]
  CONSTRAINT_NAME = 'atlassian_identities_refresh_token_length_constraint'

  disable_ddl_transaction!

  def up
    remove_check_constraint(:atlassian_identities, CONSTRAINT_NAME)
    add_check_constraint :atlassian_identities, 'octet_length(encrypted_refresh_token) <= 5000', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint(:atlassian_identities, CONSTRAINT_NAME)
    add_check_constraint :atlassian_identities, 'octet_length(encrypted_refresh_token) <= 512', CONSTRAINT_NAME
  end
end
