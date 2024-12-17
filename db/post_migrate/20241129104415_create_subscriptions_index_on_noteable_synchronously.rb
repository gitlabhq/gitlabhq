# frozen_string_literal: true

class CreateSubscriptionsIndexOnNoteableSynchronously < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  INDEX_NAME = 'index_subscriptions_on_subscribable_type_subscribable_id_and_id'
  COLUMN_NAMES = %i[subscribable_id subscribable_type id]

  # Creating prepared index in 20241106125601_update_subscriptions_index_on_noteable
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171687
  def up
    add_concurrent_index :subscriptions, COLUMN_NAMES, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :subscriptions, INDEX_NAME
  end
end
