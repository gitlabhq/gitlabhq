class CreateDeployKeys < ActiveRecord::Migration
  def change
    create_table :deploy_keys do |t|
      t.integer  "project_id",    :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "key"
      t.string   "title"
      t.string   "identifier"
    end
  end
end
