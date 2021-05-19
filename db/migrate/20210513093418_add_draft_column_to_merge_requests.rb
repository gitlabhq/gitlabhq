# frozen_string_literal: true

class AddDraftColumnToMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :merge_requests, :draft, :boolean, default: false, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :merge_requests, :draft
    end
  end
end
