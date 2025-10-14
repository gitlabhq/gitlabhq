# frozen_string_literal: true

class AddIndexToOauthAccessTokensIdWhereRevoked < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.5'

  TABLE = :oauth_access_tokens
  INDEX_NAME = 'index_oauth_access_tokens_on_id_where_revoked'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- approved exception https://gitlab.com/gitlab-org/database-team/team-tasks/-/issues/545
    add_concurrent_index TABLE, [:id],
      where: 'revoked_at IS NOT NULL',
      name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name TABLE, name: INDEX_NAME
  end
end
