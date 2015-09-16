class AddCiTags < ActiveRecord::Migration
  def change
    create_table "ci_taggings", force: true do |t|
      t.integer  "tag_id"
      t.integer  "taggable_id"
      t.string   "taggable_type"
      t.integer  "tagger_id"
      t.string   "tagger_type"
      t.string   "context",       limit: 128
      t.datetime "created_at"
    end

    add_index "ci_taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "ci_taggings_idx", unique: true, using: :btree
    add_index "ci_taggings", ["taggable_id", "taggable_type", "context"], name: "index_ci_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree

    create_table "ci_tags", force: true do |t|
      t.string  "name"
      t.integer "taggings_count", default: 0
    end

    add_index "ci_tags", ["name"], name: "index_ci_tags_on_name", unique: true, using: :btree
  end
end
