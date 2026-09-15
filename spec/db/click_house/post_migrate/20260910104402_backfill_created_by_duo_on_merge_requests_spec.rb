# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join 'db/click_house/post_migrate/main/20260910104402_backfill_created_by_duo_on_merge_requests.rb'

RSpec.describe BackfillCreatedByDuoOnMergeRequests, :click_house, feature_category: :value_stream_management do
  let(:connection) { ::ClickHouse::Connection.new(:main) }
  let(:migration) { described_class.new(connection) }

  def created_by_duo_by_id
    connection
      .select('SELECT id, created_by_duo FROM merge_requests ORDER BY id')
      .to_h { |row| [row['id'], row['created_by_duo']] }
  end

  context 'when there is data' do
    before do
      # merge_requests rows replicated before the MV enrichment existed, so all carry the default false
      connection.execute(<<~SQL)
        INSERT INTO merge_requests
          (id, iid, target_project_id, target_branch, source_branch, title, description, merge_jid,
           created_at, updated_at, traversal_path)
        SELECT number, number, 2, 'main', 'feature', 'MR', '', '', now64(6), now64(6), '1/1/2/'
        FROM numbers(101, 5)
      SQL

      # MR 101: created link
      # MR 102: source link only
      # MR 103: two created links from different workflows
      # MR 104: created link that was later deleted
      # MR 105: no link
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
          (5, 5, 104, 2, 1, '1/1/2/', now64(6), true)
      SQL
    end

    it 'flags only merge requests with a live created link' do
      expect(created_by_duo_by_id.values).to all(be(false))

      migration.up

      expect(created_by_duo_by_id).to eq({
        101 => true,
        102 => false,
        103 => true,
        104 => false,
        105 => false
      })
    end

    it 'is idempotent' do
      migration.up
      first_run = created_by_duo_by_id

      migration.up

      expect(created_by_duo_by_id).to eq(first_run)
    end
  end

  context 'when there is no data' do
    it 'completes without errors' do
      expect { migration.up }.not_to raise_error
    end
  end
end
