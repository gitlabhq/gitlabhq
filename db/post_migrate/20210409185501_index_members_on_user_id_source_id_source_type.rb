# frozen_string_literal: true

class IndexMembersOnUserIdSourceIdSourceType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_members_on_user_id_source_id_source_type'

  def up
    add_concurrent_index(:members, [:user_id, :source_id, :source_type], name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:members, INDEX_NAME)
  end
end
