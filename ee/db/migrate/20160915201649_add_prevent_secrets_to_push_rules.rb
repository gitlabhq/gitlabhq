class AddPreventSecretsToPushRules < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:push_rules, :prevent_secrets, :boolean, default: false)
  end

  def down
    remove_column(:push_rules, :prevent_secrets)
  end
end
