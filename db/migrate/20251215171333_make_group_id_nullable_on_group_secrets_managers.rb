# frozen_string_literal: true

class MakeGroupIdNullableOnGroupSecretsManagers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.8'

  def up
    with_lock_retries do
      change_column_null :group_secrets_managers, :group_id, true
    end
  end

  def down
    with_lock_retries do
      change_column_null :group_secrets_managers, :group_id, false
    end
  end
end
