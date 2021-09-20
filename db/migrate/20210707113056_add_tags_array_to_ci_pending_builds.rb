# frozen_string_literal: true

class AddTagsArrayToCiPendingBuilds < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :ci_pending_builds, :tag_ids, :integer, array: true, default: []
    end
  end

  def down
    with_lock_retries do
      remove_column :ci_pending_builds, :tag_ids
    end
  end
end
