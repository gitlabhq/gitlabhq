# frozen_string_literal: true

class RemoveTemporaryIndexForProjectTopicsToTaggings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'tmp_index_taggings_on_id_where_taggable_type_project_and_tags'
  INDEX_CONDITION = "taggable_type = 'Project' AND context = 'tags'"

  disable_ddl_transaction!

  def up
    # this index was used in 20210511095658_schedule_migrate_project_taggings_context_from_tags_to_topics
    remove_concurrent_index_by_name :taggings, INDEX_NAME
  end

  def down
    add_concurrent_index :taggings, :id, where: INDEX_CONDITION, name: INDEX_NAME
  end
end
