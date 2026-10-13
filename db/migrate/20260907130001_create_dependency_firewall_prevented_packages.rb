# frozen_string_literal: true

class CreateDependencyFirewallPreventedPackages < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  TABLE_NAME = :dependency_firewall_prevented_packages

  def up
    create_table TABLE_NAME, if_not_exists: true do |t|
      t.bigint :project_id, null: false
      # Dashboard windows always end at now, so last_blocked_at >= from answers "prevented in
      # the window"; a NULL timestamp means the package was never blocked/warned.
      t.datetime_with_timezone :first_seen_at, null: false
      t.datetime_with_timezone :last_blocked_at
      t.datetime_with_timezone :last_warned_at
      t.timestamps_with_timezone null: false
      t.column :rule_type, :smallint, null: false
      # Highest non-excepted advisory severity ever carried by the package; only meaningful for
      # vulnerability-family rules (see the CHECK constraint below).
      t.column :severity, :smallint, null: true
      # Holds a full purl (pkg:type/name@version); 512 matches pm_malware_affected_packages.
      t.text :identifier, null: false, limit: 512

      t.index [:project_id, :rule_type, :identifier],
        unique: true, name: 'i_dep_fw_prevented_packages_unique'
      t.index [:project_id, :rule_type, :last_blocked_at], name: 'i_dep_fw_prevented_packages_blocked'
      t.index [:project_id, :rule_type, :last_warned_at], name: 'i_dep_fw_prevented_packages_warned'

      # 1 = vulnerability, 4 = risk_severity in Security::DependencyFirewallPolicyRule.types.
      # Values are inlined because migrations must not depend on application code.
      t.check_constraint 'severity IS NULL OR rule_type IN (1, 4)',
        name: 'check_dep_fw_prevented_packages_severity_rule_type'

      # A row with neither timestamp is invisible to both read scopes while still occupying the
      # package's unique ledger slot, so reject it rather than let it sit there unreadable.
      t.check_constraint 'num_nonnulls(last_blocked_at, last_warned_at) >= 1',
        name: 'check_dep_fw_prevented_packages_timestamps'
    end
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
