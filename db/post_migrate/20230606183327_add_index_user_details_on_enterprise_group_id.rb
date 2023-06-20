# frozen_string_literal: true

class AddIndexUserDetailsOnEnterpriseGroupId < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_user_details_on_enterprise_group_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :user_details, :enterprise_group_id, name: INDEX_NAME

    add_concurrent_foreign_key :user_details, :namespaces, column: :enterprise_group_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :user_details, column: :enterprise_group_id
    end

    remove_concurrent_index_by_name :user_details, name: INDEX_NAME
  end
end
