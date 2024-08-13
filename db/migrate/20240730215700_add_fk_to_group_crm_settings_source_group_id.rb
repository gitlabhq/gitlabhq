# frozen_string_literal: true

class AddFkToGroupCrmSettingsSourceGroupId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  def up
    add_concurrent_foreign_key :group_crm_settings, :namespaces, column: :source_group_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :group_crm_settings, column: :source_group_id
    end
  end
end
