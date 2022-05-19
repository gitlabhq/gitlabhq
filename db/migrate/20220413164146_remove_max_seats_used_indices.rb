# frozen_string_literal: true

class RemoveMaxSeatsUsedIndices < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  MAX_SEATS_USED_INDEX = 'tmp_gitlab_subscriptions_max_seats_used_migration'
  MAX_SEATS_USED_INDEX_2 = 'tmp_gitlab_subscriptions_max_seats_used_migration_2'

  def up
    remove_concurrent_index_by_name :gitlab_subscriptions, MAX_SEATS_USED_INDEX
    remove_concurrent_index_by_name :gitlab_subscriptions, MAX_SEATS_USED_INDEX_2
  end

  def down
    add_concurrent_index :gitlab_subscriptions, :id,
                         where: "start_date >= '2021-08-02' AND start_date <= '2021-11-20' AND max_seats_used != 0 " \
                                "AND max_seats_used > seats_in_use AND max_seats_used > seats",
                         name: MAX_SEATS_USED_INDEX
    add_concurrent_index :gitlab_subscriptions, :id,
                         where: "start_date < '2021-08-02' AND max_seats_used != 0 AND max_seats_used > seats_in_use " \
                                "AND max_seats_used > seats",
                         name: MAX_SEATS_USED_INDEX_2
  end
end
