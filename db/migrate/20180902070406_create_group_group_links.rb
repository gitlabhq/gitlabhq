# frozen_string_literal: true

class CreateGroupGroupLinks < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table :group_group_links do |t|
      t.timestamps_with_timezone null: false

      t.references :shared_group, null: false,
                                  index: false,
                                  foreign_key: { on_delete: :cascade,
                                                 to_table: :namespaces }
      t.references :shared_with_group, null: false,
                                       foreign_key: { on_delete: :cascade,
                                                      to_table: :namespaces }
      t.date :expires_at
      t.index [:shared_group_id, :shared_with_group_id],
              { unique: true,
                name: 'index_group_group_links_on_shared_group_and_shared_with_group' }
      t.integer :group_access, { limit: 2,
                                 default: 30, # Gitlab::Access::DEVELOPER
                                 null: false }
    end
  end

  def down
    drop_table :group_group_links
  end
end
