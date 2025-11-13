# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join 'db/click_house/migrate/main/20251023184515_backfill_code_suggestion_events_daily_new.rb'

RSpec.describe BackfillCodeSuggestionEventsDailyNew, :click_house, feature_category: :database do
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
            (1, 1, toDateTime64('2023-01-15 10:00:00', 6, 'UTC'), '1/2', '{"ide_name":"VSCode","language":"ruby","suggestion_size":50}'),
            (1, 1, toDateTime64('2023-01-15 11:00:00', 6, 'UTC'), '1/2', '{"ide_name":"VSCode","language":"ruby","suggestion_size":30}'),
            (1, 2, toDateTime64('2023-01-15 14:00:00', 6, 'UTC'), '1/2', '{"ide_name":"JetBrains","language":"go","suggestion_size":20}'),
            (1, 2, toDateTime64('2024-01-16 09:00:00', 6, 'UTC'), '3/4', '{"ide_name":"VSCode","language":"python","suggestion_size":40}'),
            (1, 2, toDateTime64('2024-01-16 15:00:00', 6, 'UTC'), '3/4', '{"ide_name":"VSCode","language":"python","suggestion_size":25}')
            (1, 2, toDateTime64('2025-01-31 23:59:59', 6, 'UTC'), '3/4', '{"ide_name":"VSCode","language":"rust","suggestion_size":10}'),
        SQL
      )

      connection.execute('TRUNCATE TABLE code_suggestion_events_daily_new') # Clear records added from materialized view
    end

    it 'migrates data in batches correctly' do
      migration.up

      results = get_aggregated_results(connection)

      expect(results).to contain_exactly(
        hash_including(
          'date' => '2023-01-15',
          'user_id' => 1,
          'event' => 1,
          'language' => 'ruby',
          'ide_name' => 'VSCode',
          'suggestions_size_sum' => 80,
          'occurrences' => 2
        ),
        hash_including(
          'date' => '2023-01-15',
          'user_id' => 1,
          'event' => 2,
          'language' => 'go',
          'ide_name' => 'JetBrains',
          'suggestions_size_sum' => 20,
          'occurrences' => 1
        ),
        hash_including(
          'date' => '2024-01-16',
          'user_id' => 1,
          'event' => 2,
          'language' => 'python',
          'ide_name' => 'VSCode',
          'suggestions_size_sum' => 65,
          'occurrences' => 2
        ),
        hash_including(
          'date' => '2025-01-31',
          'user_id' => 1,
          'event' => 2,
          'language' => 'rust',
          'ide_name' => 'VSCode',
          'suggestions_size_sum' => 10,
          'occurrences' => 1
        )
      )
    end

    def get_aggregated_results(connection)
      connection.select(
        <<~SQL
          SELECT
            date,
            namespace_path,
            user_id,
            event,
            ide_name,
            language,
            suggestions_size_sum,
            occurrences
          FROM code_suggestion_events_daily_new FINAL
          ORDER BY date, namespace_path, user_id, event, ide_name, language
        SQL
      )
    end
  end

  context 'when there is no data' do
    before do
      connection.execute('TRUNCATE TABLE code_suggestion_events_daily_new')
    end

    it 'completes without errors' do
      expect { migration.up }.not_to raise_error
    end

    it 'leaves the target table empty' do
      migration.up

      result = connection.select('SELECT count() as cnt FROM code_suggestion_events_daily_new')
      expect(result.first['cnt']).to eq(0)
    end
  end
end
