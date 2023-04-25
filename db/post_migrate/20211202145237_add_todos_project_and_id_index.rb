# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddTodosProjectAndIdIndex < Gitlab::Database::Migration[1.0]
  # When using the methods "add_concurrent_index" or "remove_concurrent_index"
  # you must disable the use of transactions
  # as these methods can not run in an existing transaction.
  # When using "add_concurrent_index" or "remove_concurrent_index" methods make sure
  # that either of them is the _only_ method called in the migration,
  # any other changes should go in a separate migration.
  # This ensures that upon failure _only_ the index creation or removing fails
  # and can be retried or reverted easily.
  #
  # To disable transactions uncomment the following line and remove these
  # comments:
  disable_ddl_transaction!

  NEW_INDEX_NAME = 'index_todos_on_project_id_and_id'
  OLD_INDEX_NAME = 'index_todos_on_project_id'

  def up
    add_concurrent_index :todos, [:project_id, :id], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :todos, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :todos, :project_id, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :todos, NEW_INDEX_NAME
  end
end
