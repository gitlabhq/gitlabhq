# frozen_string_literal: true

class RemoveAllowEditingCommitMessagesFromProjectSettings < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    return unless column_exists?(:project_settings, :allow_editing_commit_messages)

    with_lock_retries do
      remove_column :project_settings, :allow_editing_commit_messages
    end
  end

  def down
    with_lock_retries do
      add_column :project_settings, :allow_editing_commit_messages, :boolean, default: false, null: false
    end
  end
end
