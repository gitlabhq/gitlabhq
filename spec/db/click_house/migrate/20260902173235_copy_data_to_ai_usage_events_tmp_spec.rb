# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join 'db/click_house/migrate/main/20260902173235_copy_data_to_ai_usage_events_tmp.rb'

# The rebuild recomputes `traversal_path` for rows still carrying the `'0/'` DEFAULT sentinel,
# resolving it from the leaf namespace id, the last path component in both the legacy (`9/42/`)
# and the org-scoped (`7/9/42/`) format. Rows the dual write already populated pass through
# untouched, so the transform is idempotent and the copy can run over every row regardless of when
# the writer switched over.
#
# The migration is not invoked directly: it copies `ai_usage_events` into `ai_usage_events_tmp`,
# but once the suite's schema is fully migrated the swap has reversed those names. The copy is
# driven in the correct orientation here, reusing the migration's own column list so the two
# cannot drift apart.
RSpec.describe CopyDataToAiUsageEventsTmp, :click_house, feature_category: :value_stream_management do
  let(:connection) { ::ClickHouse::Connection.new(:main) }

  # Pre-rebuild definition: namespace_path as the leading sort key, traversal_path defaulting to
  # the `'0/'` sentinel.
  let(:pre_rebuild_table) { 'ai_usage_events_tmp' }
  # Rebuilt definition: traversal_path is the leading sort key.
  let(:rebuilt_table) { 'ai_usage_events' }

  let(:org_scoped_path) { '7/9/42/' }

  # No reload needed: the CACHE-layout dictionary fetches uncached keys from its source on first
  # access, and the after hook below leaves the cache empty.
  before do
    connection.execute(<<~SQL)
      INSERT INTO namespace_traversal_paths (id, traversal_path, version, deleted)
      VALUES (42, '#{org_scoped_path}', now64(6), false)
    SQL

    insert_row(user_id: 1, namespace_path: '9/42/')
    insert_row(user_id: 2, namespace_path: '9/42/', traversal_path: org_scoped_path) # dual written
    insert_row(user_id: 3, namespace_path: '9/4242/')                                # namespace since deleted
  end

  # Resolving a key leaves it cached, which makes the suite's `truncate_tables` helper try to
  # TRUNCATE a Dictionary and fail for every later example in the process. Emptying the source and
  # reloading evicts it.
  after do
    connection.execute('TRUNCATE TABLE namespace_traversal_paths')
    connection.execute('SYSTEM RELOAD DICTIONARY namespace_traversal_paths_dict')
  end

  # Leaving traversal_path at the `'0/'` sentinel stands in for a row written before the dual write.
  def insert_row(user_id:, namespace_path:, traversal_path: '0/')
    connection.execute(<<~SQL)
      INSERT INTO #{pre_rebuild_table} (user_id, event, timestamp, namespace_path, traversal_path, extras)
      VALUES (#{user_id}, 2, toDateTime64('2026-06-01 10:00:00', 6, 'UTC'), '#{namespace_path}',
        '#{traversal_path}', '{}')
    SQL
  end

  def run_copy
    connection.execute(<<~SQL)
      INSERT INTO #{rebuilt_table} (#{described_class::COLUMNS.join(', ')})
      SELECT #{described_class::SELECT_EXPRESSIONS.join(', ')} FROM #{pre_rebuild_table}
    SQL
  end

  def copied_paths_by_user
    connection
      .select("SELECT user_id, namespace_path, traversal_path FROM #{rebuilt_table} ORDER BY user_id")
      .to_h { |row| [row['user_id'], [row['namespace_path'], row['traversal_path']]] }
  end

  it 'resolves rows still carrying the sentinel to the org-scoped path' do
    run_copy

    expect(copied_paths_by_user[1]).to eq(['9/42/', org_scoped_path])
  end

  it 'leaves dual written rows unchanged' do
    run_copy

    expect(copied_paths_by_user[2]).to eq(['9/42/', org_scoped_path])
  end

  # Also covers installations without Siphon, where every lookup misses because the dictionary
  # source is never populated.
  it 'keeps the sentinel when the leaf namespace is gone from the dictionary' do
    run_copy

    expect(copied_paths_by_user[3]).to eq(['9/4242/', '0/'])
  end

  it 'preserves namespace_path so downstream materialized views keep the legacy format' do
    run_copy

    expect(copied_paths_by_user.values.map(&:first)).to contain_exactly('9/42/', '9/42/', '9/4242/')
  end

  it 'is idempotent when the tail window is re-copied before the swap' do
    run_copy
    run_copy

    expect(copied_paths_by_user[1]).to eq(['9/42/', org_scoped_path])
  end
end
