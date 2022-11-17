# frozen_string_literal: true
class ChangeScimIdentityGroupIdRemoveNull < Gitlab::Database::Migration[2.0]
  def up
    change_column_null :scim_identities, :group_id, true
  end

  def down
    # There may now be nulls in the table, so we cannot re-add the constraint here.
  end
end
