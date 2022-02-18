# frozen_string_literal: true

class ScheduleFixIncorrectMaxSeatsUsed2 < Gitlab::Database::Migration[1.0]
  MIGRATION = 'FixIncorrectMaxSeatsUsed'
  TMP_IDX_NAME = 'tmp_gitlab_subscriptions_max_seats_used_migration_2'

  disable_ddl_transaction!

  def up
    add_concurrent_index :gitlab_subscriptions, :id, where: "start_date < '2021-08-02' AND max_seats_used != 0 AND max_seats_used > seats_in_use AND max_seats_used > seats", name: TMP_IDX_NAME

    return unless Gitlab.com?

    migrate_in(1.hour, MIGRATION, ['batch_2_for_start_date_before_02_aug_2021'])
  end

  def down
    remove_concurrent_index_by_name :gitlab_subscriptions, TMP_IDX_NAME
  end
end
