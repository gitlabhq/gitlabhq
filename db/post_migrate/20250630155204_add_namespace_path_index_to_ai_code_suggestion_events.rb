# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddNamespacePathIndexToAiCodeSuggestionEvents < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.2'

  TABLE_NAME = :ai_code_suggestion_events
  COLUMN_NAMES = "((substring(namespace_path FROM '([0-9]+)[^0-9]*$'))::bigint), timestamp, id"

  INDEX_NAME = :idx_project_namespace_id_from_namespace_path_timestamp_and_id

  def up
    add_concurrent_partitioned_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
