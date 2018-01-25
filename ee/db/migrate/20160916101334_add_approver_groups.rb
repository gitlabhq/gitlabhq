# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable Migration/Timestamps
class AddApproverGroups < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true

  DOWNTIME_REASON = 'Adding foreign key'.freeze

  def change
    create_table :approver_groups do |t|
      t.integer :target_id, null: false
      t.string :target_type, null: false
      t.integer :group_id, null: false

      t.timestamps null: true

      t.index [:target_id, :target_type]
      t.index :group_id
    end

    add_foreign_key :approver_groups, :namespaces, column: :group_id, on_delete: :cascade # rubocop: disable Migration/AddConcurrentForeignKey
  end
end
