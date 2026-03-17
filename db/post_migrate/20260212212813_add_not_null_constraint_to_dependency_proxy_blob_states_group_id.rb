# frozen_string_literal: true

class AddNotNullConstraintToDependencyProxyBlobStatesGroupId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.10'

  def up
    add_not_null_constraint :dependency_proxy_blob_states, :group_id
  end

  def down
    remove_not_null_constraint :dependency_proxy_blob_states, :group_id
  end
end
