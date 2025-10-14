# frozen_string_literal: true

class AddIndexToOauthAccessGrantsIdWhereRevoked < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.5'

  TABLE = :oauth_access_grants
  INDEX_NAME = 'index_oauth_access_grants_on_id_where_revoked'

  def up
    add_concurrent_index TABLE, [:id],
      where: 'revoked_at IS NOT NULL',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE, name: INDEX_NAME
  end
end
