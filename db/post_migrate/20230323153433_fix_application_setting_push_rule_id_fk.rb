# frozen_string_literal: true

class FixApplicationSettingPushRuleIdFk < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  # This migration fixes missing `track_record_deletions(:push_rules)`
  # where the `application_settings.push_rule_id` would not be reset
  # after removing push rule.

  def up
    execute <<~SQL
      UPDATE application_settings SET push_rule_id=NULL
      WHERE push_rule_id IS NOT NULL AND NOT EXISTS (
        SELECT * FROM push_rules WHERE push_rules.id = application_settings.push_rule_id
      )
    SQL
  end

  def down; end
end
