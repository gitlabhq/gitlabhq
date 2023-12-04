# frozen_string_literal: true

class DropTmpIndexOauthAccessTokensOnIdWhereExpiresInNull < Gitlab::Database::Migration[2.1]
  TMP_INDEX = 'tmp_index_oauth_access_tokens_on_id_where_expires_in_null'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :oauth_access_tokens, TMP_INDEX
  end

  def down
    add_concurrent_index :oauth_access_tokens, :id, where: "expires_in IS NULL", name: TMP_INDEX
  end
end
