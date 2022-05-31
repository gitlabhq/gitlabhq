# frozen_string_literal: true

class CreateIssuableResourceLinks < Gitlab::Database::Migration[2.0]
  def change
    create_table :issuable_resource_links do |t|
      t.references :issue, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.text :link_text, null: true, limit: 255
      t.text :link, null: false, limit: 2200
      t.integer :link_type, null: false, limit: 2, default: 0 # general resource link

      t.timestamps_with_timezone null: false
    end
  end
end
