# frozen_string_literal: true

class CreateDependencyFirewallActivityStats < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def up
    create_table :dependency_firewall_activity_stats, if_not_exists: true do |t|
      # Nullable: an "allowed" outcome usually matches no rule (NULL = no rule matched).
      t.bigint :dependency_firewall_policy_rule_id, null: true
      t.bigint :project_id, null: false
      t.bigint :count, null: false, default: 0
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
      # Start of the hourly bucket (UTC, truncated to the hour) the activity falls into. Hourly
      # granularity supports rolling windows finer than a day (e.g. last 6h/12h/24h) via SUM.
      t.datetime_with_timezone :stat_time, null: false
      t.column :outcome, :smallint, null: false

      # NULLS NOT DISTINCT so a NULL rule_id still collides on upsert (one row per bucket).
      t.index [:dependency_firewall_policy_rule_id, :project_id, :stat_time, :outcome],
        unique: true, nulls_not_distinct: true, name: 'i_dep_fw_activity_stats_unique'
      t.index [:project_id, :stat_time], name: 'i_dep_fw_activity_stats_project_time'
    end
  end

  def down
    drop_table :dependency_firewall_activity_stats, if_exists: true
  end
end
