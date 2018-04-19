# This migration comes from acts_as_taggable_on_engine (originally 6)
#
# It has been modified to handle no-downtime GitLab migrations. Several
# indexes have been removed since they are not needed for GitLab.
class AddMissingIndexesActsAsTaggableOnEngine < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :taggings, :tag_id unless index_exists? :taggings, :tag_id
    add_concurrent_index :taggings, [:taggable_id, :taggable_type] unless index_exists? :taggings, [:taggable_id, :taggable_type]
  end

  def down
    remove_concurrent_index :taggings, :tag_id
    remove_concurrent_index :taggings, [:taggable_id, :taggable_type]
  end
end
