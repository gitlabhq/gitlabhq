class AddRegexpUsesRe2ToPushRules < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # Default value to true for new values while keeping NULL for existing ones
    add_column :push_rules, :regexp_uses_re2, :boolean
    change_column_default :push_rules, :regexp_uses_re2, true
  end

  def down
    remove_column :push_rules, :regexp_uses_re2
  end
end
