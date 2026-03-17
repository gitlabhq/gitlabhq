# frozen_string_literal: true

class CreateSiphonCiRunners < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_ci_runners
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        creator_id Nullable(Int64),
        created_at DateTime64(6, 'UTC') default now() CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') default now() CODEC(Delta, ZSTD(1)),
        contacted_at Nullable(DateTime64(6, 'UTC')),
        token_expires_at Nullable(DateTime64(6, 'UTC')),
        public_projects_minutes_cost_factor Float64 DEFAULT 1.0,
        private_projects_minutes_cost_factor Float64 DEFAULT 1.0,
        access_level Int64 DEFAULT 0,
        maximum_timeout Nullable(Int64),
        runner_type Int16 CODEC(DoubleDelta, ZSTD),
        registration_type Int16 DEFAULT 0,
        creation_state Int16 DEFAULT 0,
        active Bool DEFAULT true CODEC(ZSTD(1)),
        run_untagged Bool DEFAULT true CODEC(ZSTD(1)),
        locked Bool DEFAULT false CODEC(ZSTD(1)),
        name Nullable(String),
        token_encrypted String DEFAULT '',
        description String default '' CODEC(ZSTD(3)),
        maintainer_note String default '' CODEC(ZSTD(3)),
        allowed_plans Array(String) DEFAULT [],
        allowed_plan_ids Array(Int64) DEFAULT [],
        organization_id Nullable(Int64),
        allowed_plan_name_uids Array(Int16) DEFAULT [],
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1))
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (id, runner_type)
      SETTINGS index_granularity = 2048
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_ci_runners
    SQL
  end
end
