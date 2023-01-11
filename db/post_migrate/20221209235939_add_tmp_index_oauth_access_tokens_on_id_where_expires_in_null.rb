# frozen_string_literal: true

class AddTmpIndexOauthAccessTokensOnIdWhereExpiresInNull < Gitlab::Database::Migration[2.1]
  TMP_INDEX = 'tmp_index_oauth_access_tokens_on_id_where_expires_in_null'

  disable_ddl_transaction!

  def up
    # Temporary index to be removed in %15.9 or later https://gitlab.com/gitlab-org/gitlab/-/issues/385343
    add_concurrent_index :oauth_access_tokens, :id, where: "expires_in IS NULL", name: TMP_INDEX
  end

  def down
    remove_concurrent_index_by_name :oauth_access_tokens, TMP_INDEX
  end
end
