# frozen_string_literal: true

class AddSharedRunnersEnabledAndOverrideToNamespaces < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :namespaces, :shared_runners_enabled, :boolean, default: true, null: false
      add_column :namespaces, :allow_descendants_override_disabled_shared_runners, :boolean, default: false, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :namespaces, :shared_runners_enabled, :boolean
      remove_column :namespaces, :allow_descendants_override_disabled_shared_runners, :boolean
    end
  end
end
