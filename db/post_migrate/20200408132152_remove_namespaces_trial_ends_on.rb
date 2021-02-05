# frozen_string_literal: true

class RemoveNamespacesTrialEndsOn < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :namespaces, 'index_namespaces_on_trial_ends_on'

    with_lock_retries do
      remove_column :namespaces, :trial_ends_on
    end
  end

  def down
    unless column_exists?(:namespaces, :trial_ends_on)
      with_lock_retries do
        add_column :namespaces, :trial_ends_on, :datetime_with_timezone # rubocop:disable Migration/AddColumnsToWideTables
      end
    end

    add_concurrent_index :namespaces, :trial_ends_on, using: 'btree', where: 'trial_ends_on IS NOT NULL'
  end
end
