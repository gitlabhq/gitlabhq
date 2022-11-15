# frozen_string_literal: true
class ChangeScimOauthAccessTokenGroupIdRemoveNull < Gitlab::Database::Migration[2.0]
  def up
    change_column_null :scim_oauth_access_tokens, :group_id, true
  end

  def down
    # There may now be nulls in the table, so we cannot re-add the constraint here.
  end
end
