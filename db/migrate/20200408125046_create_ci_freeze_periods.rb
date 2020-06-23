# frozen_string_literal: true

class CreateCiFreezePeriods < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:ci_freeze_periods)
      create_table :ci_freeze_periods do |t|
        t.references :project, foreign_key: true, null: false
        t.text :freeze_start, null: false
        t.text :freeze_end, null: false
        t.text :cron_timezone, null: false

        t.timestamps_with_timezone null: false
      end
    end

    add_text_limit :ci_freeze_periods, :freeze_start, 998
    add_text_limit :ci_freeze_periods, :freeze_end, 998
    add_text_limit :ci_freeze_periods, :cron_timezone, 255
  end

  def down
    drop_table :ci_freeze_periods
  end
end
