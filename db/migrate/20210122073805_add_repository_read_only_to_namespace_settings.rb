# frozen_string_literal: true

class AddRepositoryReadOnlyToNamespaceSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :namespace_settings, :repository_read_only, :boolean, default: false, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :namespace_settings, :repository_read_only
    end
  end
end
