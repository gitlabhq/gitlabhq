# frozen_string_literal: true

class AddRemoveOnIssueCloseToLabels < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :labels, :remove_on_close, :boolean, null: false, default: false
    end
  end

  def down
    with_lock_retries do
      remove_column :labels, :remove_on_close, :boolean
    end
  end
end
