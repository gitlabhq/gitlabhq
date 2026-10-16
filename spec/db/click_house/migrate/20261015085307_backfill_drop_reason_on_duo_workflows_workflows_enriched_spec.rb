# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join(
  'db/click_house/migrate/main/20261015085307_backfill_drop_reason_on_duo_workflows_workflows_enriched.rb'
)

RSpec.describe BackfillDropReasonOnDuoWorkflowsWorkflowsEnriched, :click_house, feature_category: :duo_agent_platform do
  let(:connection) { ::ClickHouse::Connection.new(:main) }
  let(:migration) { described_class.new(connection) }

  let(:emitted_at) { "toDateTime64('2026-10-12 10:00:00', 6, 'UTC')" }
  let(:failed_at) { "toDateTime64('2026-10-12 11:00:00', 6, 'UTC')" }

  def enriched_rows
    connection.select(<<~SQL).to_h { |row| [row['id'], row.except('id')] }
      SELECT id, drop_reason, toString(later_closed_merge_request_ids) AS later_closed, toString(_version) AS version
      FROM duo_workflows_workflows_enriched FINAL
      ORDER BY id
    SQL
  end

  context 'when there is data' do
    before do
      # Flow 1 failed with a reason after its enriched row was emitted.
      # Flow 2 never recorded a reason.
      # Flow 3 already carries its reason in the enriched table.
      # Flow 4 recorded a reason, then a retry cleared it.
      connection.execute(<<~SQL)
        INSERT INTO siphon_duo_workflows_workflows
          (id, traversal_path, created_at, updated_at, user_id, status, drop_reason,
           _siphon_replicated_at, _siphon_watermark)
        VALUES
          (1, '1/', #{emitted_at}, #{emitted_at}, 7, 1, NULL, #{emitted_at}, #{emitted_at}),
          (2, '1/', #{emitted_at}, #{emitted_at}, 7, 2, NULL, #{emitted_at}, #{emitted_at}),
          (3, '1/', #{emitted_at}, #{emitted_at}, 7, 3, 'no_activity', #{emitted_at}, #{emitted_at}),
          (4, '1/', #{emitted_at}, #{emitted_at}, 7, 3, 'job_failed', #{emitted_at}, #{emitted_at})
      SQL

      # Later versions go in their own insert: a single insert collapses same-key rows
      # (optimize_on_insert), which would hide the NULL-handling the migration relies on.
      connection.execute(<<~SQL)
        INSERT INTO siphon_duo_workflows_workflows
          (id, traversal_path, created_at, updated_at, user_id, status, drop_reason,
           _siphon_replicated_at, _siphon_watermark)
        VALUES
          (1, '1/', #{emitted_at}, #{failed_at}, 7, 3, 'job_failed', #{failed_at}, #{failed_at}),
          (4, '1/', #{emitted_at}, #{failed_at}, 7, 1, NULL, #{failed_at}, #{failed_at})
      SQL

      # Enriched rows as the views left them before the column existed: flow 1 was already
      # repaired by the mr_outcomes view, so it carries a later_closed entry.
      connection.execute(<<~SQL)
        INSERT INTO duo_workflows_workflows_enriched
          (id, traversal_path, created_at, updated_at, user_id, status, drop_reason,
           later_closed_merge_request_ids, _version, _watermark)
        VALUES
          (1, '1/', #{emitted_at}, #{failed_at}, 7, 3, NULL, [5], #{failed_at}, #{failed_at}),
          (2, '1/', #{emitted_at}, #{emitted_at}, 7, 2, NULL, [], #{emitted_at}, #{emitted_at}),
          (3, '1/', #{emitted_at}, #{emitted_at}, 7, 3, 'no_activity', [], #{emitted_at}, #{emitted_at}),
          (4, '1/', #{emitted_at}, #{failed_at}, 7, 1, NULL, [], #{failed_at}, #{failed_at})
      SQL
    end

    it 'fills the reason only for rows whose latest Siphon row has one' do
      migration.up

      expect(enriched_rows.transform_values { |row| row['drop_reason'] }).to eq(
        1 => 'job_failed',
        2 => nil,
        3 => 'no_activity',
        4 => nil
      )
    end

    it 'keeps the mr_outcomes repair and reinserts one microsecond above the current version' do
      migration.up

      expect(enriched_rows[1]).to eq(
        'drop_reason' => 'job_failed',
        'later_closed' => '[5]',
        'version' => '2026-10-12 11:00:00.000001'
      )
    end

    it 'leaves the untouched rows at their original version' do
      migration.up

      expect(enriched_rows.except(1).transform_values { |row| row['version'] }).to eq(
        2 => '2026-10-12 10:00:00.000000',
        3 => '2026-10-12 10:00:00.000000',
        4 => '2026-10-12 11:00:00.000000'
      )
    end

    it 'is idempotent' do
      migration.up
      first_run = enriched_rows

      migration.up

      expect(enriched_rows).to eq(first_run)
    end
  end

  context 'when there is no data' do
    it 'completes without errors' do
      expect { migration.up }.not_to raise_error
    end
  end
end
