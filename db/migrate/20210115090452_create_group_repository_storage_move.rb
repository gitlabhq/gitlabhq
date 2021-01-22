# frozen_string_literal: true

class CreateGroupRepositoryStorageMove < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:group_repository_storage_moves)
      with_lock_retries do
        create_table :group_repository_storage_moves do |t|
          t.timestamps_with_timezone
          t.references :group, references: :namespace, column: :group_id, index: true, null: false
          t.integer :state, limit: 2, default: 1, null: false
          t.text :source_storage_name, null: false
          t.text :destination_storage_name, null: false

          t.foreign_key :namespaces, column: :group_id, on_delete: :cascade
        end
      end
    end

    add_text_limit(:group_repository_storage_moves, :source_storage_name, 255, constraint_name: 'group_repository_storage_moves_source_storage_name')
    add_text_limit(:group_repository_storage_moves, :destination_storage_name, 255, constraint_name: 'group_repository_storage_moves_destination_storage_name')
  end

  def down
    with_lock_retries do
      drop_table :group_repository_storage_moves
    end
  end
end
