class CreateService < ActiveRecord::Migration
  def change
    create_table :services, force: true do |t|
      t.string   :type
      t.string   :title
      t.integer  :project_id,                 null: false
      t.datetime :created_at
      t.datetime :updated_at
      t.boolean  :active,     default: false, null: false
      t.text     :properties
    end

    add_index :services, [:project_id], name: :index_services_on_project_id, using: :btree
  end
end
