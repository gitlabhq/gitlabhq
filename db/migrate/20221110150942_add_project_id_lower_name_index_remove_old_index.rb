# frozen_string_literal: true

class AddProjectIdLowerNameIndexRemoveOldIndex < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_im_timeline_event_tags_name_project_id'
  NEW_INDEX_NAME = 'index_im_timeline_event_tags_on_lower_name_and_project_id'

  disable_ddl_transaction!

  def up
    # Add new index
    add_concurrent_index :incident_management_timeline_event_tags, 'project_id, LOWER(name)',
      unique: true, name: NEW_INDEX_NAME

    # Remove old index
    remove_concurrent_index_by_name :incident_management_timeline_event_tags, INDEX_NAME
  end

  def down
    # Add old index
    add_concurrent_index :incident_management_timeline_event_tags, [:project_id, :name],
      unique: true, name: INDEX_NAME

    # Remove new index
    remove_concurrent_index_by_name :incident_management_timeline_event_tags, NEW_INDEX_NAME
  end
end
