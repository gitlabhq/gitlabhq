# frozen_string_literal: true

class AddIssueIndexToRequirement < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_requirements_on_issue_id'

  def up
    add_concurrent_index :requirements, :issue_id, name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name :requirements, INDEX_NAME
  end
end
