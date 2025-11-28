# frozen_string_literal: true

class RemoveTempSourceIdFromSystemAccessGroupMicrosoftApplications < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  INDEX_NAME = 'index_group_microsoft_applications_on_temp_source_id'

  def up
    remove_column :system_access_group_microsoft_applications, :temp_source_id
  end

  def down
    add_column :system_access_group_microsoft_applications, :temp_source_id, :bigint
    change_column_comment :system_access_group_microsoft_applications, :temp_source_id,
      'Temporary column to store graph access tokens id'
    add_concurrent_index :system_access_group_microsoft_applications, :temp_source_id,
      unique: true, name: INDEX_NAME
  end
end
