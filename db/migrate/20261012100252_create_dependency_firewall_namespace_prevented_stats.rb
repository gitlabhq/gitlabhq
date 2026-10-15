# frozen_string_literal: true

class CreateDependencyFirewallNamespacePreventedStats < Gitlab::Database::Migration[2.3]
  milestone '19.6'

  TABLE_NAME = :dependency_firewall_namespace_prevented_stats

  def up
    create_table TABLE_NAME do |t|
      t.references :namespace, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.date :window_start, null: false
      t.integer :vulnerabilities_prevented, null: false, default: 0
      t.integer :malicious_packages_prevented, null: false, default: 0
      t.integer :malicious_packages_warned_only, null: false, default: 0
      t.integer :license_risks_prevented, null: false, default: 0
      t.integer :license_risks_warned_only, null: false, default: 0
      t.integer :severity_critical, null: false, default: 0
      t.integer :severity_high, null: false, default: 0
      t.integer :severity_medium, null: false, default: 0
      t.integer :severity_low, null: false, default: 0
      t.integer :severity_info, null: false, default: 0
      t.integer :severity_unknown, null: false, default: 0
      t.integer :window_days, null: false, limit: 2

      t.index [:namespace_id, :window_days], unique: true,
        name: 'i_dep_fw_ns_prevented_stats_on_namespace_and_window'

      t.check_constraint 'window_days IN (7, 30)', name: 'check_dep_fw_ns_prevented_stats_window_days'
    end
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
