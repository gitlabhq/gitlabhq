# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join 'db/click_house/post_migrate/main/20251210231344_backfill_agent_platform_sessions.rb'

RSpec.describe BackfillAgentPlatformSessions, :click_house, feature_category: :database do
  let_it_be(:connection) { ::ClickHouse::Connection.new(:main) }

  let(:migration) { described_class.new(connection) }

  before do
    migration.down
  end

  context 'when there is data' do
    before do
      connection.execute(
        <<~SQL
          INSERT INTO ai_usage_events
            (user_id, event, timestamp, namespace_path, extras)
          VALUES
            (1, 8, toDateTime64('2025-01-15 10:00:00', 6, 'UTC'), '1/2', '{"project_id":1,"session_id":1,"flow_type":"chat","environment":""}'),
            (1, 9, toDateTime64('2025-01-15 11:00:00', 6, 'UTC'), '1/2', '{"project_id":1,"session_id":1,"flow_type":"chat","environment":""}'),
            (1, 19, toDateTime64('2025-02-15 14:00:00', 6, 'UTC'), '1/2', '{"project_id":1,"session_id":1,"flow_type":"chat","environment":""}'),
            (1, 9, toDateTime64('2025-02-16 09:00:00', 6, 'UTC'), '3/4', '{"project_id":1,"session_id":2,"flow_type":"chat","environment":""}'),
            (1, 9, toDateTime64('2025-03-16 15:00:00', 6, 'UTC'), '3/4', '{"project_id":1,"session_id":3,"flow_type":"chat","environment":""}'),
            (1, 9, toDateTime64('2025-03-31 23:59:59', 6, 'UTC'), '3/4', '{"project_id":1,"session_id":4,"flow_type":"chat","environment":""}')
        SQL
      )

      connection.execute('TRUNCATE TABLE agent_platform_sessions') # Clear records added from materialized view
    end

    it 'migrates data in batches correctly' do
      migration.up

      results = get_aggregated_results(connection)

      expect(results).to contain_exactly(
        hash_including(
          'namespace_path' => '1/2',
          'user_id' => 1,
          'session_id' => 1,
          'flow_type' => 'chat',
          'environment' => '',
          'created_at' => Time.parse('2025-01-15 10:00:00.000000000 +0000'),
          'started_at' => Time.parse('2025-01-15 11:00:00.000000000 +0000'),
          'finished_at' => Time.parse('2025-02-15 14:00:00.000000000 +0000')
        ),
        hash_including(
          'namespace_path' => '3/4',
          'user_id' => 1,
          'session_id' => 2,
          'flow_type' => 'chat',
          'environment' => '',
          'created_at' => nil,
          'started_at' => Time.parse('2025-02-16 09:00:00.000000000 +0000'),
          'finished_at' => nil
        ),
        hash_including(
          'namespace_path' => '3/4',
          'user_id' => 1,
          'session_id' => 3,
          'flow_type' => 'chat',
          'environment' => '',
          'created_at' => nil,
          'started_at' => Time.parse('2025-03-16 15:00:00.000000000 +0000'),
          'finished_at' => nil
        ),
        hash_including(
          'namespace_path' => '3/4',
          'user_id' => 1,
          'session_id' => 4,
          'flow_type' => 'chat',
          'environment' => '',
          'created_at' => nil,
          'started_at' => Time.parse('2025-03-31 23:59:59.000000000 +0000'),
          'finished_at' => nil
        )
      )
    end

    def get_aggregated_results(connection)
      connection.select(
        <<~SQL
          SELECT
            namespace_path,
            user_id,
            session_id,
            flow_type,
            environment,
            anyIfMerge(created_event_at) AS created_at,
            anyIfMerge(started_event_at) AS started_at,
            anyIfMerge(finished_event_at) AS finished_at
          FROM agent_platform_sessions FINAL
          GROUP BY namespace_path, user_id, session_id, flow_type, environment
          ORDER BY namespace_path, user_id, session_id, flow_type, environment
        SQL
      )
    end
  end

  context 'when there is no data' do
    before do
      connection.execute('TRUNCATE TABLE agent_platform_sessions')
    end

    it 'completes without errors' do
      expect { migration.up }.not_to raise_error
    end

    it 'leaves the target table empty' do
      migration.up

      result = connection.select('SELECT count() as cnt FROM agent_platform_sessions')
      expect(result.first['cnt']).to eq(0)
    end
  end
end
