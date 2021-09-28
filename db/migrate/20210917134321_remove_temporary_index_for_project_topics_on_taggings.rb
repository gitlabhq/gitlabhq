# frozen_string_literal: true

class RemoveTemporaryIndexForProjectTopicsOnTaggings < Gitlab::Database::Migration[1.0]
  MIGRATION = 'ExtractProjectTopicsIntoSeparateTable'
  INDEX_NAME = 'tmp_index_taggings_on_id_where_taggable_type_project'
  INDEX_CONDITION = "taggable_type = 'Project'"

  disable_ddl_transaction!

  def up
    # Ensure that no background jobs of 20210730104800_schedule_extract_project_topics_into_separate_table remain
    finalize_background_migration MIGRATION
    # this index was used in 20210730104800_schedule_extract_project_topics_into_separate_table
    remove_concurrent_index_by_name :taggings, INDEX_NAME
  end

  def down
    add_concurrent_index :taggings, :id, where: INDEX_CONDITION, name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation
  end
end
