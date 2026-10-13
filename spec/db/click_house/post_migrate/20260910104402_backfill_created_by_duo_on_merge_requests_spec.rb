# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join 'db/click_house/post_migrate/main/20260910104402_backfill_created_by_duo_on_merge_requests.rb'

RSpec.describe BackfillCreatedByDuoOnMergeRequests, :click_house, feature_category: :value_stream_management do
  let(:connection) { ::ClickHouse::Connection.new(:main) }
  let(:migration) { described_class.new(connection) }
  let(:boolean_type) { ActiveModel::Type::Boolean.new }

  let(:expected_created_by_duo) do
    {
      101 => true,
      102 => false,
      103 => true,
      104 => false,
      105 => false
    }
  end

  def enrich!
    ClickHouse::Client.execute('SYSTEM REFRESH VIEW merge_requests_enriched_mv', click_house_admin_database)
    ClickHouse::Client.execute('SYSTEM WAIT VIEW merge_requests_enriched_mv', click_house_admin_database)
  end

  def migrate!
    migration.up
    enrich!
  end

  def created_by_duo_by_id
    connection
      .select('SELECT id, created_by_duo FROM merge_requests FINAL ORDER BY id')
      .to_h { |row| [row['id'], boolean_type.cast(row['created_by_duo'])] }
  end

  context 'when there is data' do
    before do
      # merge_requests rows enriched before created_by_duo existed, so all carry the default false.
      # MR 106 was deleted later.
      connection.execute(<<~SQL)
        INSERT INTO merge_requests
          (id, iid, target_project_id, target_branch, source_branch, title, description, merge_jid,
           created_at, updated_at, traversal_path, _siphon_replicated_at, _siphon_deleted)
        SELECT number, number, 2, 'main', 'feature', 'MR', '', '', now64(6), now64(6), '1/1/2/',
               toDateTime64('2026-09-01 10:00:00', 6, 'UTC'), false
        FROM numbers(101, 6)
      SQL

      connection.execute(<<~SQL)
        INSERT INTO merge_requests
          (id, iid, target_project_id, target_branch, source_branch, title, description, merge_jid,
           created_at, updated_at, traversal_path, _siphon_replicated_at, _siphon_deleted)
        VALUES
          (106, 106, 2, 'main', 'feature', 'MR', '', '', now64(6), now64(6), '1/1/2/',
           toDateTime64('2026-09-01 11:00:00', 6, 'UTC'), true)
      SQL

      # MR 101: created link
      # MR 102: source link only
      # MR 103: two created links from different workflows
      # MR 104: created link that was later deleted
      # MR 105: no link
      # MR 106: created link, but the merge request itself is deleted
      connection.execute(<<~SQL)
        INSERT INTO siphon_duo_workflows_workflow_merge_requests
          (id, workflow_id, merge_request_id, project_id, link_type, traversal_path,
           _siphon_replicated_at, _siphon_deleted)
        VALUES
          (1, 1, 101, 2, 1, '1/1/2/', now64(6), false),
          (2, 2, 102, 2, 0, '1/1/2/', now64(6), false),
          (3, 3, 103, 2, 1, '1/1/2/', now64(6), false),
          (4, 4, 103, 2, 1, '1/1/2/', now64(6), false),
          (5, 5, 104, 2, 1, '1/1/2/', now64(6) - INTERVAL 1 MINUTE, false),
          (5, 5, 104, 2, 1, '1/1/2/', now64(6), true),
          (6, 6, 106, 2, 1, '1/1/2/', now64(6), false)
      SQL
    end

    it 'flags only live merge requests with a live created link' do
      expect(created_by_duo_by_id).to eq(expected_created_by_duo.transform_values { false })

      migrate!

      expect(created_by_duo_by_id).to eq(expected_created_by_duo)
    end

    it 'reinserts the rows with a higher version instead of mutating them' do
      migrate!

      # +1us from the reinsert, +1us from the enrichment
      row = connection.select(<<~SQL).first
        SELECT title, toString(_siphon_replicated_at) AS version
        FROM merge_requests FINAL
        WHERE id = 101
      SQL

      expect(row).to eq('title' => 'MR', 'version' => '2026-09-01 10:00:00.000002')
    end

    it 'is idempotent' do
      migrate!
      first_run = created_by_duo_by_id

      migrate!

      expect(created_by_duo_by_id).to eq(first_run)
    end

    context 'when the links span multiple batches' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 2)
      end

      it 'runs one insert per batch and flags every merge request with a live created link' do
        # link ids 1..6 in batches of 2
        expect(migration).to receive(:execute).exactly(3).times.and_call_original

        migrate!

        expect(created_by_duo_by_id).to eq(expected_created_by_duo)
      end
    end
  end

  context 'when there is no data' do
    it 'completes without errors' do
      expect { migrate! }.not_to raise_error
    end
  end
end
