# frozen_string_literal: true

class ScheduleFixIncorrectMaxSeatsUsed < Gitlab::Database::Migration[1.0]
  DOWNTIME = false
  TMP_IDX_NAME = 'tmp_gitlab_subscriptions_max_seats_used_migration'

  disable_ddl_transaction!

  def up
    add_concurrent_index :gitlab_subscriptions, :id, where: "start_date >= '2021-08-02' AND start_date <= '2021-11-20' AND max_seats_used != 0 AND max_seats_used > seats_in_use AND max_seats_used > seats", name: TMP_IDX_NAME

    return unless Gitlab.com?

    migrate_in(1.hour, 'FixIncorrectMaxSeatsUsed')
  end

  def down
    remove_concurrent_index_by_name :gitlab_subscriptions, TMP_IDX_NAME
  end
end
