# rubocop:disable RemoveIndex
class AddUniqueIndexToSubscriptions < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'This migration requires downtime because it changes a column to not accept null values.'

  disable_ddl_transaction!

  def up
    add_concurrent_index :subscriptions, [:subscribable_id, :subscribable_type, :user_id, :project_id], { unique: true, name: 'index_subscriptions_on_subscribable_and_user_id_and_project_id' }
    remove_index :subscriptions, name: 'subscriptions_user_id_and_ref_fields' if index_name_exists?(:subscriptions, 'subscriptions_user_id_and_ref_fields')
  end

  def down
    add_concurrent_index :subscriptions, [:subscribable_id, :subscribable_type, :user_id], { unique: true, name: 'subscriptions_user_id_and_ref_fields' }
    remove_index :subscriptions, name: 'index_subscriptions_on_subscribable_and_user_id_and_project_id' if index_name_exists?(:subscriptions, 'index_subscriptions_on_subscribable_and_user_id_and_project_id')
  end
end
