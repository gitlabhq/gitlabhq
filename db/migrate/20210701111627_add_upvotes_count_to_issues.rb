# frozen_string_literal: true

class AddUpvotesCountToIssues < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :issues, :upvotes_count, :integer, default: 0, null: false
    end
  end

  def down
    remove_column :issues, :upvotes_count
  end
end
