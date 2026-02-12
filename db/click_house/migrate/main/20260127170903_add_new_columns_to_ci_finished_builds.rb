# frozen_string_literal: true

class AddNewColumnsToCiFinishedBuilds < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds
      ADD COLUMN IF NOT EXISTS `namespace_path` String DEFAULT '0/',
      ADD COLUMN IF NOT EXISTS `failure_reason` LowCardinality(String) DEFAULT '',
      ADD COLUMN IF NOT EXISTS `when` LowCardinality(String) DEFAULT '',
      ADD COLUMN IF NOT EXISTS `manual` Bool DEFAULT false,
      ADD COLUMN IF NOT EXISTS `allow_failure` Bool DEFAULT false,
      ADD COLUMN IF NOT EXISTS `user_id` UInt64 DEFAULT 0,
      ADD COLUMN IF NOT EXISTS `artifacts_filename` String DEFAULT '',
      ADD COLUMN IF NOT EXISTS `artifacts_size` UInt64 DEFAULT 0,
      ADD COLUMN IF NOT EXISTS `retries_count` UInt16 DEFAULT 0,
      ADD COLUMN IF NOT EXISTS `runner_tags` Array(String) DEFAULT [],
      ADD COLUMN IF NOT EXISTS `job_definition_id` UInt64 DEFAULT 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds
      DROP COLUMN IF EXISTS `namespace_path`,
      DROP COLUMN IF EXISTS `failure_reason`,
      DROP COLUMN IF EXISTS `when`,
      DROP COLUMN IF EXISTS `manual`,
      DROP COLUMN IF EXISTS `allow_failure`,
      DROP COLUMN IF EXISTS `user_id`,
      DROP COLUMN IF EXISTS `artifacts_filename`,
      DROP COLUMN IF EXISTS `artifacts_size`,
      DROP COLUMN IF EXISTS `retries_count`,
      DROP COLUMN IF EXISTS `runner_tags`,
      DROP COLUMN IF EXISTS `job_definition_id`
    SQL
  end
end
