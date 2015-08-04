# This migration comes from acts_as_taggable_on_engine (originally 2)
class AddMissingUniqueIndices < ActiveRecord::Migration
  def self.up
    add_index :tags, :name, unique: true

    # pre-GitLab v6.7.0 may not have these indices since there were no
    # migrations for them
    if index_exists?(:taggings, :tag_id)
      remove_index :taggings, :tag_id
    end

    if index_exists?(:taggings, [:taggable_id, :taggable_type, :context])
      remove_index :taggings, [:taggable_id, :taggable_type, :context]
    end
    add_index :taggings,
              [:tag_id, :taggable_id, :taggable_type, :context, :tagger_id, :tagger_type],
              unique: true, name: 'taggings_idx'
  end

  def self.down
    remove_index :tags, :name

    remove_index :taggings, name: 'taggings_idx'
    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :taggable_type, :context]
  end
end
