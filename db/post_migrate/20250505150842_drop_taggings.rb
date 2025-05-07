# frozen_string_literal: true

class DropTaggings < Gitlab::Database::Migration[2.3]
  milestone '18.0'
  skip_require_disable_ddl_transactions!

  def up
    drop_table :taggings
  end

  def down
    create_table :taggings do |t|
      t.bigint :tag_id
      t.string :taggable_type
      t.bigint :tagger_id
      t.string :tagger_type
      t.string :context
      t.timestamp :created_at # rubocop: disable Migration/Datetime -- rollback must match the type
      t.bigint :taggable_id

      t.index :tag_id, name: 'index_taggings_on_tag_id'
      t.index [:taggable_id, :taggable_type, :context],
        name: 'index_taggings_on_taggable_id_and_taggable_type_and_context'
      t.index [:tag_id, :taggable_id, :taggable_type, :context, :tagger_id, :tagger_type],
        unique: true,
        name: 'taggings_idx'
    end
  end
end
