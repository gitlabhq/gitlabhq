# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'merge_requests created_by_duo enrichment', :click_house, feature_category: :value_stream_management do
  let(:conn) { ClickHouse::Connection.new(:main) }

  before do
    # MR 101: created by a namespace-level flow, so the link's traversal_path is the group's, not the project's
    # MR 102: source link only
    # MR 103: two created links from different workflows
    # MR 104: created link that was later deleted
    # MR 105: no link
    conn.execute <<~SQL
      INSERT INTO siphon_duo_workflows_workflow_merge_requests
        (id, workflow_id, merge_request_id, project_id, namespace_id, link_type, traversal_path,
         _siphon_replicated_at, _siphon_deleted)
      VALUES
        (1, 1, 101, NULL, 1, 1, '1/1/', now64(6), false),
        (2, 2, 102, 2, NULL, 0, '1/1/2/', now64(6), false),
        (3, 3, 103, 2, NULL, 1, '1/1/2/', now64(6), false),
        (4, 4, 103, 2, NULL, 1, '1/1/2/', now64(6), false),
        (5, 5, 104, 2, NULL, 1, '1/1/2/', now64(6) - INTERVAL 1 MINUTE, false),
        (5, 5, 104, 2, NULL, 1, '1/1/2/', now64(6), true)
    SQL

    conn.execute <<~SQL
      INSERT INTO siphon_merge_requests
        (id, iid, target_project_id, target_branch, source_branch, title, description, merge_jid,
         created_at, updated_at, traversal_path)
      VALUES
        (101, 1, 2, 'main', 'feature', 'MR', '', '', now64(6), now64(6), '1/1/2/'),
        (102, 2, 2, 'main', 'feature', 'MR', '', '', now64(6), now64(6), '1/1/2/'),
        (103, 3, 2, 'main', 'feature', 'MR', '', '', now64(6), now64(6), '1/1/2/'),
        (104, 4, 2, 'main', 'feature', 'MR', '', '', now64(6), now64(6), '1/1/2/'),
        (105, 5, 2, 'main', 'feature', 'MR', '', '', now64(6), now64(6), '1/1/2/')
    SQL

    # created_by_duo is a joined column, so the insert path leaves it false and the
    # enrichment pass fills it in. Nothing here is time-dependent, so one pass is enough.
    conn.execute('SYSTEM REFRESH VIEW merge_requests_enriched_mv')
    conn.execute('SYSTEM WAIT VIEW merge_requests_enriched_mv')
  end

  it 'marks only merge requests with a live created link', :aggregate_failures do
    rows = conn.select(<<~SQL)
      SELECT id, created_by_duo
      FROM merge_requests FINAL
      ORDER BY id
    SQL

    expect(rows.map { |row| row.values_at('id', 'created_by_duo') }).to eq([
      [101, true],
      [102, false],
      [103, true],
      [104, false],
      [105, false]
    ])

    # MR 103 has two created links, so a missing GROUP BY in the CTE would fan the
    # enriched row out into one row per link.
    enriched = conn.select(<<~SQL)
      SELECT id, count() AS versions
      FROM merge_requests
      WHERE _siphon_enriched
      GROUP BY id
      ORDER BY id
    SQL

    expect(enriched.map { |row| row.values_at('id', 'versions') }).to eq([
      [101, 1],
      [102, 1],
      [103, 1],
      [104, 1],
      [105, 1]
    ])
  end
end
