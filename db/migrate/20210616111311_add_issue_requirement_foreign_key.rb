# frozen_string_literal: true

class AddIssueRequirementForeignKey < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TARGET_TABLE = :requirements

  def up
    add_concurrent_foreign_key TARGET_TABLE, :issues, column: :issue_id
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(TARGET_TABLE, column: :issue_id)
    end
  end
end
