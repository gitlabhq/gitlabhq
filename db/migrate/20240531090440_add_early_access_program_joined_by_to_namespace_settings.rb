# frozen_string_literal: true

class AddEarlyAccessProgramJoinedByToNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :namespace_settings, :early_access_program_joined_by_id, :bigint, if_not_exists: true
    end
  end

  def down
    with_lock_retries do
      remove_column :namespace_settings, :early_access_program_joined_by_id, :bigint, if_exists: true
    end
  end
end
