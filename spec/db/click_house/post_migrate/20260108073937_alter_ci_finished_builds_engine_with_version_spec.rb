# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join(
  'db/click_house/post_migrate/main/20260108073937_alter_ci_finished_builds_engine_with_version.rb'
)

RSpec.describe AlterCiFinishedBuildsEngineWithVersion, :click_house, feature_category: :fleet_visibility do
  let(:connection) { ::ClickHouse::Connection.new(:main) }
  let(:migration) { described_class.new(connection) }

  # Full engine clause including parameters, partition/sorting keys and SETTINGS
  # (e.g. "ReplacingMergeTree(version, deleted) PARTITION BY ... SETTINGS ...")
  # from system.tables.engine_full.
  def current_engine_full
    connection.select(
      ClickHouse::Client::Query.new(
        raw_query: "SELECT engine_full FROM system.tables WHERE name = 'ci_finished_builds' " \
          "AND database = currentDatabase()"
      )
    ).pick('engine_full')
  end

  # Just the engine clause with parameters, e.g. "ReplacingMergeTree" or
  # "ReplacingMergeTree(version, deleted)".
  def current_engine_clause
    current_engine_full.split(' PARTITION BY ', 2).first
  end

  # The SETTINGS clause as a single comparable string, e.g.
  # "index_granularity = 8192, use_async_block_ids_cache = true, deduplicate_merge_projection_mode = 'rebuild'".
  def current_settings_clause
    current_engine_full.split(' SETTINGS ', 2).last
  end

  def column_names
    connection.select(
      ClickHouse::Client::Query.new(
        raw_query: "SELECT name FROM system.columns WHERE table = 'ci_finished_builds' " \
          "AND database = currentDatabase() ORDER BY position"
      )
    ).map { |row| row['name'] }
  end

  def show_create_ci_finished_builds
    connection.select(
      ClickHouse::Client::Query.new(raw_query: "SHOW CREATE TABLE ci_finished_builds")
    ).pick('statement')
  end

  def insert_sample_row(id)
    connection.execute(<<~SQL)
      INSERT INTO ci_finished_builds (id, project_id, finished_at)
      VALUES (#{id}, 100, now())
    SQL
  end

  def row_count_for(id)
    connection.select(
      ClickHouse::Client::Query.new(
        raw_query: "SELECT count() AS c FROM ci_finished_builds WHERE id = #{id}"
      )
    ).pick('c')
  end

  # The shared :click_house schema applies all migrations, so this one is
  # already up. Roll it back first to restore the pre-migration engine, then
  # verify migration.up swaps it again.
  before do
    migration.down
  end

  after do
    migration.down
  end

  describe '#up' do
    let(:sample_row_id) { 1 }

    before do
      insert_sample_row(sample_row_id)
    end

    it 'swaps the engine from ReplacingMergeTree to ReplacingMergeTree(version, deleted)' do
      expect { migration.up }
        .to change { current_engine_clause }
        .from('ReplacingMergeTree')
        .to('ReplacingMergeTree(version, deleted)')
    end

    it 'preserves existing rows' do
      expect { migration.up }.not_to change { row_count_for(sample_row_id) }.from(1)
    end

    # The CREATE TABLE ... AS source ENGINE = ... SETTINGS ... syntax fully
    # replaces (rather than merges) the source's SETTINGS, so the migration
    # must restate every setting it wants to keep on the swapped table.
    #
    # The exact SETTINGS string format varies by ClickHouse version (booleans
    # render as `true`/`false` on 24+, `1`/`0` on 23.x; `deduplicate_merge_projection_mode`
    # only exists on 24.1+). We don't pin the expected value; we just assert
    # the clause doesn't change across the swap, which catches accidental
    # drops or additions of settings regardless of CH version.
    context 'with engine-level SETTINGS on the source table' do
      it 'keeps the SETTINGS clause identical on the swapped table' do
        expect { migration.up }.not_to change { current_settings_clause }
      end
    end

    # Regression test for https://gitlab.com/gitlab-org/gitlab/-/work_items/593129.
    # When post-deployment migrations are deferred (the default on Self-Managed
    # upgrades), regular migrations with later timestamps can add columns and
    # projections to ci_finished_builds before this migration runs. The tmp
    # table must mirror the live source structure, not a snapshot taken when
    # the migration was authored.
    context 'when extra columns and a projection were added before this migration runs' do
      let(:extra_columns) { %w[migration_test_column_one migration_test_column_two] }
      let(:extra_projection) { 'migration_test_projection' }

      before do
        connection.execute(<<~SQL)
          ALTER TABLE ci_finished_builds
            ADD COLUMN IF NOT EXISTS `migration_test_column_one` String DEFAULT '',
            ADD COLUMN IF NOT EXISTS `migration_test_column_two` UInt64 DEFAULT 0
        SQL

        connection.execute(<<~SQL)
          ALTER TABLE ci_finished_builds
            ADD PROJECTION IF NOT EXISTS #{extra_projection}
              (
                SELECT project_id, count() AS total
                GROUP BY project_id
              )
        SQL
      end

      after do
        connection.execute(<<~SQL)
          ALTER TABLE ci_finished_builds
            DROP PROJECTION IF EXISTS #{extra_projection}
            SETTINGS mutations_sync = 1
        SQL

        connection.execute(<<~SQL)
          ALTER TABLE ci_finished_builds
            DROP COLUMN IF EXISTS `migration_test_column_one`,
            DROP COLUMN IF EXISTS `migration_test_column_two`
        SQL
      end

      it 'still swaps the engine without raising INCOMPATIBLE_COLUMNS' do
        expect { migration.up }
          .to change { current_engine_clause }
          .from('ReplacingMergeTree')
          .to('ReplacingMergeTree(version, deleted)')
      end

      it 'preserves the extra columns on the swapped table' do
        migration.up

        expect(column_names).to include(*extra_columns)
      end

      it 'preserves the extra projection on the swapped table' do
        migration.up

        # The gitlab ClickHouse user cannot read system.projections, so verify
        # via SHOW CREATE TABLE which renders projections inline.
        expect(show_create_ci_finished_builds).to include(extra_projection)
      end
    end
  end

  describe '#down' do
    context 'when the table already has the (version, deleted) engine' do
      before do
        migration.up
      end

      it 'reverts the engine back to ReplacingMergeTree without parameters' do
        expect { migration.down }
          .to change { current_engine_clause }
          .from('ReplacingMergeTree(version, deleted)')
          .to('ReplacingMergeTree')
      end
    end

    context 'when the table does not have the (version, deleted) engine' do
      # The top-level before { migration.down } has already left the table in
      # the pre-up state, so running down again should be a no-op.
      it 'leaves the engine unchanged' do
        expect { migration.down }.not_to change { current_engine_clause }.from('ReplacingMergeTree')
      end
    end
  end
end
