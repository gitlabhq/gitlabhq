# frozen_string_literal: true

class AddIssueIdToRequirement < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :requirements, :issue_id, :bigint, null: true
    end
  end

  def down
    with_lock_retries do
      remove_column :requirements, :issue_id
    end
  end
end
