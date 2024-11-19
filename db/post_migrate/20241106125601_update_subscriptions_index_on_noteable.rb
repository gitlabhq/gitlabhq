# frozen_string_literal: true

class UpdateSubscriptionsIndexOnNoteable < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  INDEX_NAME = 'index_subscriptions_on_subscribable_type_subscribable_id_and_id'
  COLUMN_NAMES = %i[subscribable_id subscribable_type id]

  # Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/502840
  #
  # This is designed to improve iterating over related subscriptions records in batches:
  def up
    prepare_async_index :subscriptions, COLUMN_NAMES, name: INDEX_NAME
  end

  def down
    unprepare_async_index :subscriptions, COLUMN_NAMES, name: INDEX_NAME
  end
end
