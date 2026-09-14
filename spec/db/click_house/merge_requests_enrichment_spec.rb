# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'merge_requests enrichment', :click_house, feature_category: :database do
  let(:conn) { ClickHouse::Connection.new(:main) }

  let(:mr_id) { 1001 }
  let(:path) { '1/1/' }
  let(:base_version) { '2026-09-01 10:00:00.000000' }

  # Trigger the scheduled view automatically
  def enrich!
    conn.execute('SYSTEM REFRESH VIEW merge_requests_enriched_mv')
    conn.execute('SYSTEM WAIT VIEW merge_requests_enriched_mv')
  end

  def insert_mr(id: mr_id, version: base_version, deleted: false, title: 'Test MR')
    conn.execute <<~SQL
      INSERT INTO siphon_merge_requests
        (id, iid, target_branch, source_branch, title, description, merge_jid,
         target_project_id, created_at, updated_at, traversal_path,
         _siphon_replicated_at, _siphon_deleted)
      VALUES
        (#{id}, 1, 'main', 'feature', '#{title}', '', '', 7,
         '2026-09-01 10:00:00', '2026-09-01 10:00:00', '#{path}',
         '#{version}', #{deleted})
    SQL
  end

  def enriched_row(id: mr_id)
    conn.select(<<~SQL).first
      SELECT
        id,
        _siphon_enriched,
        toString(_siphon_replicated_at) AS version,
        arraySort(reviewers.user_id) AS reviewer_ids,
        arraySort(reviewers.state) AS reviewer_states,
        arraySort(assignees.user_id) AS assignee_ids,
        arraySort(approvals.user_id) AS approver_ids,
        arraySort(label_ids.label_id) AS labels,
        arraySort(award_emojis.name) AS emoji_names,
        metric_diff_size,
        metric_commits_count
      FROM merge_requests FINAL
      WHERE id = #{id}
    SQL
  end

  describe 'the insert path' do
    it 'makes the row readable straight away, without the denormalized columns' do
      insert_mr

      row = conn.select(<<~SQL).first
        SELECT _siphon_enriched, length(reviewers) AS reviewers, length(label_ids) AS labels,
               metric_diff_size, _siphon_watermark > now() - INTERVAL 1 MINUTE AS seen_now
        FROM merge_requests
        WHERE id = #{mr_id} AND _siphon_replicated_at = '#{base_version}'
      SQL

      expect(row['_siphon_enriched']).to be(false)
      expect(row['reviewers']).to eq(0)
      expect(row['labels']).to eq(0)
      expect(row['metric_diff_size']).to be_nil
      expect(row['seen_now']).to be_truthy
    end
  end

  describe 'the enrichment pass' do
    before do
      insert_mr

      # One live reviewer, one deleted, one superseded by a later state.
      conn.execute <<~SQL
        INSERT INTO siphon_merge_request_reviewers
          (id, user_id, merge_request_id, traversal_path, state, created_at,
           _siphon_replicated_at, _siphon_deleted)
        VALUES
          (1, 11, #{mr_id}, '#{path}', 1, '2026-09-01 10:00:00', '#{base_version}', false),
          (2, 12, #{mr_id}, '#{path}', 1, '2026-09-01 10:00:00', '#{base_version}', true),
          (3, 13, #{mr_id}, '#{path}', 1, '2026-09-01 10:00:00', '#{base_version}', false),
          (3, 13, #{mr_id}, '#{path}', 9, '2026-09-01 10:00:00', '2026-09-01 11:00:00.000000', false)
      SQL

      conn.execute <<~SQL
        INSERT INTO siphon_merge_request_assignees
          (id, user_id, merge_request_id, traversal_path, project_id, created_at, _siphon_replicated_at)
        VALUES (1, 21, #{mr_id}, '#{path}', 7, '2026-09-01 10:00:00', '#{base_version}')
      SQL

      conn.execute <<~SQL
        INSERT INTO siphon_approvals
          (id, merge_request_id, user_id, traversal_path, project_id, created_at, updated_at, _siphon_replicated_at)
        VALUES (1, #{mr_id}, 31, '#{path}', 7, '2026-09-01 10:00:00', '2026-09-01 10:00:00', '#{base_version}')
      SQL

      # The Issue-typed link shares the target_id and must not leak in.
      conn.execute <<~SQL
        INSERT INTO siphon_label_links
          (id, label_id, target_id, target_type, traversal_path, namespace_id,
           created_at, updated_at, _siphon_replicated_at)
        VALUES
          (1, 41, #{mr_id}, 'MergeRequest', '#{path}', 1, '2026-09-01 10:00:00', '2026-09-01 10:00:00', '#{base_version}'),
          (2, 42, #{mr_id}, 'Issue', '#{path}', 1, '2026-09-01 10:00:00', '2026-09-01 10:00:00', '#{base_version}')
      SQL

      conn.execute <<~SQL
        INSERT INTO siphon_award_emoji
          (id, name, user_id, awardable_type, awardable_id, traversal_path,
           created_at, updated_at, _siphon_replicated_at)
        VALUES
          (1, 'thumbsup', 51, 'MergeRequest', #{mr_id}, '#{path}', '2026-09-01 10:00:00', '2026-09-01 10:00:00', '#{base_version}'),
          (2, 'tada', 52, 'Issue', #{mr_id}, '#{path}', '2026-09-01 10:00:00', '2026-09-01 10:00:00', '#{base_version}')
      SQL

      conn.execute <<~SQL
        INSERT INTO siphon_merge_request_metrics
          (id, merge_request_id, traversal_path, created_at, updated_at,
           diff_size, commits_count, _siphon_replicated_at)
        VALUES (1, #{mr_id}, '#{path}', '2026-09-01 10:00:00', '2026-09-01 10:00:00', 42, 3, '#{base_version}')
      SQL
    end

    it 'fills in every denormalized column, honouring deletes, versions and types' do
      enrich!
      row = enriched_row

      expect(row['_siphon_enriched']).to be(true)
      expect(row['reviewer_ids']).to eq([11, 13])   # 12 was deleted
      expect(row['reviewer_states']).to eq([1, 9])  # 13 took its later state
      expect(row['assignee_ids']).to eq([21])
      expect(row['approver_ids']).to eq([31])
      expect(row['labels']).to eq([41])             # the Issue link stayed out
      expect(row['emoji_names']).to eq(%w[thumbsup])
      expect(row['metric_diff_size']).to eq(42)
      expect(row['metric_commits_count']).to eq(3)
      # source version + 1us, which is what keeps it from beating a tombstone
      expect(row['version']).to eq('2026-09-01 10:00:00.000001')
    end

    it 'leaves the row alone when run again with nothing changed' do
      enrich!
      before_state = enriched_row

      enrich!
      enrich!

      expect(enriched_row).to eq(before_state)
      expect(conn.select("SELECT count() AS c FROM merge_requests FINAL WHERE id = #{mr_id}")
               .first['c']).to eq(1)
    end
  end

  describe 'a change to a child table only' do
    before do
      insert_mr
      conn.execute <<~SQL
        INSERT INTO siphon_merge_request_reviewers
          (id, user_id, merge_request_id, traversal_path, state, created_at, _siphon_replicated_at)
        VALUES (1, 11, #{mr_id}, '#{path}', 1, '2026-09-01 10:00:00', '#{base_version}')
      SQL
      enrich!
    end

    it 'is picked up while the row is still inside the buffer window' do
      conn.execute <<~SQL
        INSERT INTO siphon_merge_request_reviewers
          (id, user_id, merge_request_id, traversal_path, state, created_at, _siphon_replicated_at)
        VALUES (1, 11, #{mr_id}, '#{path}', 4, '2026-09-01 10:00:00', '2026-09-01 12:00:00.000000')
      SQL

      enrich!

      expect(enriched_row['reviewer_states']).to eq([4])
    end

    # Past the window the row is gone from the buffer, so only a refresh package
    # brings it back. This is why refresh_on_change stays configured.
    it 'is picked up after the buffer expired, once a refresh package re-queues the row' do
      conn.execute <<~SQL
        INSERT INTO siphon_merge_request_reviewers
          (id, user_id, merge_request_id, traversal_path, state, created_at, _siphon_replicated_at)
        VALUES (1, 11, #{mr_id}, '#{path}', 4, '2026-09-01 10:00:00', '2026-09-01 12:00:00.000000')
      SQL
      conn.execute('TRUNCATE TABLE merge_requests_base')

      enrich!
      expect(enriched_row['reviewer_states']).to eq([1])

      # What the consumer's refresh path issues.
      conn.execute <<~SQL
        INSERT INTO siphon_merge_requests
          (id, iid, target_branch, source_branch, title, description, merge_jid,
           target_project_id, created_at, updated_at, traversal_path, _siphon_replicated_at)
        SELECT id, iid, target_branch, source_branch, title, description, merge_jid,
               target_project_id, created_at, updated_at, traversal_path,
               addMicroseconds(max(_siphon_replicated_at), 1)
        FROM merge_requests
        WHERE id = #{mr_id}
        GROUP BY id, iid, target_branch, source_branch, title, description, merge_jid,
                 target_project_id, created_at, updated_at, traversal_path
      SQL

      enrich!

      expect(enriched_row['reviewer_states']).to eq([4])
    end
  end

  describe 'a deleted merge request' do
    before do
      insert_mr
      conn.execute <<~SQL
        INSERT INTO siphon_merge_request_reviewers
          (id, user_id, merge_request_id, traversal_path, state, created_at, _siphon_replicated_at)
        VALUES (1, 11, #{mr_id}, '#{path}', 1, '2026-09-01 10:00:00', '#{base_version}')
      SQL
      enrich!
    end

    it 'is not resurrected by a later pass' do
      insert_mr(version: '2026-09-01 13:00:00.000000', deleted: true)

      enrich!
      enrich!

      expect(conn.select("SELECT count() AS c FROM merge_requests FINAL WHERE id = #{mr_id}")
               .first['c']).to eq(0)
    end
  end

  describe 'a merge request with no children' do
    it 'is marked enriched with empty arrays rather than left behind' do
      insert_mr(id: 2001)
      insert_mr(id: 2002)

      enrich!

      [2001, 2002].each do |id|
        row = enriched_row(id: id)
        expect(row['_siphon_enriched']).to be(true)
        expect(row['reviewer_ids']).to eq([])
        expect(row['labels']).to eq([])
        expect(row['metric_diff_size']).to be_nil
      end
    end
  end
end
