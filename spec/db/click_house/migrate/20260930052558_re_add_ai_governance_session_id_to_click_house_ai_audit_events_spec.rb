# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join(
  'db/click_house/migrate/main/20260930052558_re_add_ai_governance_session_id_to_click_house_ai_audit_events.rb'
)

RSpec.describe ReAddAiGovernanceSessionIdToClickHouseAiAuditEvents, feature_category: :duo_agent_platform do
  let(:connection) { instance_double(ClickHouse::Connection, replicated_engine?: false, version: '25.3') }
  let(:migration) { described_class.new(connection) }
  let(:sql) { 'ALTER TABLE ai_audit_events DROP PROJECTION IF EXISTS by_workflow_id' }
  let(:executed) { [] }

  let(:cannot_assign_alter) do
    ClickHouse::Client::DatabaseError.new('Code: 517. DB::Exception: ... (CANNOT_ASSIGN_ALTER)')
  end

  let(:mutation_not_finished) do
    ClickHouse::Client::DatabaseError.new(
      "Code: 36. DB::Exception: Cannot drop projection by_workflow_id because it's affected by mutation " \
        "with ID 'mutation_1.txt' which is not finished yet. (BAD_ARGUMENTS)"
    )
  end

  before do
    allow(migration).to receive(:sleep)
  end

  describe '#execute_when_idle' do
    it 'retries while the table is busy, then succeeds' do
      calls = 0
      allow(connection).to receive(:execute) do
        calls += 1
        raise cannot_assign_alter if calls == 1
        raise mutation_not_finished if calls == 2
      end

      migration.send(:execute_when_idle, sql, interval: 0)

      expect(connection).to have_received(:execute).with(sql).exactly(3).times
      expect(migration).to have_received(:sleep).with(0).twice
    end

    it 'raises TableBusyError once the deadline passes while still busy' do
      allow(connection).to receive(:execute).and_raise(cannot_assign_alter)

      expect { migration.send(:execute_when_idle, sql, timeout: 0, interval: 0) }
        .to raise_error(described_class::TableBusyError, /still has a running mutation/)
    end

    it 're-raises other database errors immediately' do
      error = ClickHouse::Client::DatabaseError.new('Code: 62. DB::Exception: Syntax error. (SYNTAX_ERROR)')
      allow(connection).to receive(:execute).and_raise(error)

      expect { migration.send(:execute_when_idle, sql) }.to raise_error(error)
      expect(connection).to have_received(:execute).once
    end
  end

  describe 'statement order' do
    before do
      allow(connection).to receive(:execute) { |query| executed << query.squish }
    end

    it 'swaps the SELECT * projection for explicit ones around the new column on #up' do
      migration.up

      expect(executed).to match([
        a_string_including('DROP PROJECTION IF EXISTS by_workflow_id '),
        a_string_including('ADD COLUMN IF NOT EXISTS ai_governance_session_id'),
        a_string_including('ADD PROJECTION IF NOT EXISTS by_workflow_id_v2'),
        a_string_including('ADD PROJECTION IF NOT EXISTS by_ai_governance_session_id'),
        a_string_including('MATERIALIZE PROJECTION by_workflow_id_v2'),
        a_string_including('MATERIALIZE PROJECTION by_ai_governance_session_id')
      ])
    end

    it 'restores the original projection on #down' do
      migration.down

      expect(executed).to match([
        a_string_including('DROP PROJECTION IF EXISTS by_workflow_id_v2'),
        a_string_including('DROP PROJECTION IF EXISTS by_ai_governance_session_id'),
        a_string_including('DROP COLUMN IF EXISTS ai_governance_session_id'),
        a_string_including('ADD PROJECTION IF NOT EXISTS by_workflow_id ( SELECT *'),
        a_string_including('MATERIALIZE PROJECTION by_workflow_id ')
      ])
    end
  end
end
