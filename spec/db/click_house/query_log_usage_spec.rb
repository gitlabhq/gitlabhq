# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'query_log_usage materialized view', :click_house, feature_category: :database do
  let(:conn) { ClickHouse::Connection.new(:main) }

  # A query-level SETTINGS log_comment overrides the &log_comment= URL param that
  # ClickHouse::HttpClient appends, so this exercises the real attribution path.
  def query_with_log_comment(log_comment)
    conn.execute("SELECT 1 SETTINGS log_comment = #{ClickHouse::Client::Quoting.quote(log_comment)}")
    conn.execute('SYSTEM FLUSH LOGS')
  end

  def usage_rows
    conn.select('SELECT * FROM query_log_usage')
  end

  it 'extracts the log_comment dimensions and the query metrics', :aggregate_failures do
    query_with_log_comment({
      root_namespace_id: 42,
      organization_id: 7,
      user_id: 9,
      correlation_id: 'abc123',
      application: 'web',
      feature_category: 'database'
    }.to_json)

    rows = usage_rows.select { |r| r['root_namespace_id'] == 42 }

    expect(rows.map { |row| row['query_id'] }.uniq.size).to eq(1)

    row = rows.first

    expect(row).to include(
      'organization_id' => 7,
      'user_id' => 9,
      'correlation_id' => 'abc123',
      'application' => 'web',
      'feature_category' => 'database',
      'query_kind' => 'Select',
      'exception_code' => 0
    )
    expect(row['read_bytes']).to be >= 0
    expect(row['os_cpu_virtual_time_us']).to be >= 0
    expect(row['memory_usage_bytes']).to be > 0
    expect(row['log_comment']).to include('"root_namespace_id":42')
  end

  it 'skips rows whose log_comment has no usable root_namespace_id' do
    unusable = [
      'not json at all',
      'gkg-prefixed-thing',
      '{}',
      '{"root_namespace_id":null}',
      '[1,2,3]',
      '{"root_namespace_id":"abc"}'
    ]
    unusable.each { |log_comment| query_with_log_comment(log_comment) }

    expect(usage_rows.map { |row| row['log_comment'] }).not_to include(*unusable)
  end
end
