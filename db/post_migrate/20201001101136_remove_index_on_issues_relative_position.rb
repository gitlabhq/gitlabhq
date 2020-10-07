# frozen_string_literal: true

class RemoveIndexOnIssuesRelativePosition < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_issues_on_relative_position'
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name(:issues, INDEX_NAME)
  end

  def down
    add_concurrent_index(:issues, :relative_position, name: INDEX_NAME)
  end
end
