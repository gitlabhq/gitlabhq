# frozen_string_literal: true

class TrackGroupWikiRepositoryRecordChanges < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.10'

  INSERT_FUNCTION_NAME_CUSTOM_COLUMN = 'insert_into_loose_foreign_keys_deleted_records_with_group_id'

  def up
    track_record_deletions_with_custom_column(:group_wiki_repositories,
      column: :group_id, function_name: INSERT_FUNCTION_NAME_CUSTOM_COLUMN)
  end

  def down
    untrack_record_deletions(:group_wiki_repositories)
    drop_function(INSERT_FUNCTION_NAME_CUSTOM_COLUMN)
  end
end
