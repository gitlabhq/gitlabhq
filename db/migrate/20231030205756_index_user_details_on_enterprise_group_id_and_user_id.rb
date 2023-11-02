# frozen_string_literal: true

class IndexUserDetailsOnEnterpriseGroupIdAndUserId < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  disable_ddl_transaction!

  INDEX_NAME = 'index_user_details_on_enterprise_group_id_and_user_id'
  INDEX_NAME_TO_REMOVE = 'index_user_details_on_enterprise_group_id'

  def up
    add_concurrent_index(:user_details, [:enterprise_group_id, :user_id], name: INDEX_NAME)

    remove_concurrent_index_by_name :user_details, INDEX_NAME_TO_REMOVE
  end

  def down
    remove_concurrent_index_by_name :user_details, INDEX_NAME

    add_concurrent_index :user_details, :enterprise_group_id, name: INDEX_NAME_TO_REMOVE
  end
end
