class CreateBadges < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :badges do |t|
      t.string     :link_url, null: false
      t.string     :image_url, null: false
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: true
      t.integer    :group_id, index: true, null: true
      t.string     :type, null: false

      t.timestamps_with_timezone null: false
    end

    add_foreign_key :badges, :namespaces, column: :group_id, on_delete: :cascade
  end
end
