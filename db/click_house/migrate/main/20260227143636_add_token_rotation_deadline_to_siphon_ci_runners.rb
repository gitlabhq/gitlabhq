# frozen_string_literal: true

class AddTokenRotationDeadlineToSiphonCiRunners < ClickHouse::Migration
  def up
    execute <<-SQL
      ALTER TABLE siphon_ci_runners ADD COLUMN IF NOT EXISTS token_rotation_deadline DateTime64(6, 'UTC') DEFAULT toDateTime64('9999-12-31 23:59:59.999999', 6, 'UTC');
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE siphon_ci_runners DROP COLUMN IF EXISTS token_rotation_deadline;
    SQL
  end
end
