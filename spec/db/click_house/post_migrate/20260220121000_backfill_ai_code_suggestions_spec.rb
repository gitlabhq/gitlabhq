# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join 'db/click_house/post_migrate/main/20260220121000_backfill_ai_code_suggestions.rb'

RSpec.describe BackfillAiCodeSuggestions, :click_house, feature_category: :database do
  include ClickHouseHelpers

  let_it_be(:connection) { ::ClickHouse::Connection.new(:main) }

  let(:migration) { described_class.new(connection) }

  before do
    migration.down
  end

  context 'when there is data' do
    before do
      clickhouse_fixture(:ai_usage_events, [
        {
          user_id: 1,
          event: 2,
          timestamp: Time.zone.parse('2023-01-15 10:00:00 UTC'),
          namespace_path: 'group1/project1',
          extras: {
            unique_tracking_id: 'uid1',
            language: 'ruby',
            branch_name: 'main',
            ide_name: 'VSCode',
            ide_vendor: 'Microsoft',
            ide_version: '1.80.0',
            extension_name: 'GitLab Workflow',
            extension_version: '3.0.0',
            language_server_version: '1.0.0',
            model_name: 'claude',
            model_engine: 'anthropic',
            suggestion_size: 50
          }.to_json
        },
        {
          user_id: 1,
          event: 3,
          timestamp: Time.zone.parse('2023-01-15 10:01:00 UTC'),
          namespace_path: 'group1/project1',
          extras: {
            unique_tracking_id: 'uid1',
            language: 'ruby',
            suggestion_size: 50
          }.to_json
        },
        {
          user_id: 1,
          event: 2,
          timestamp: Time.zone.parse('2023-01-15 11:00:00 UTC'),
          namespace_path: 'group1/project1',
          extras: {
            unique_tracking_id: 'uid2',
            language: 'python',
            branch_name: 'feature',
            ide_name: 'JetBrains',
            suggestion_size: 30
          }.to_json
        },
        {
          user_id: 1,
          event: 4,
          timestamp: Time.zone.parse('2023-01-15 11:02:00 UTC'),
          namespace_path: 'group1/project1',
          extras: {
            unique_tracking_id: 'uid2',
            language: 'python',
            suggestion_size: 30
          }.to_json
        },
        {
          user_id: 2,
          event: 2,
          timestamp: Time.zone.parse('2023-01-20 09:00:00 UTC'),
          namespace_path: 'group2/project2',
          extras: {
            unique_tracking_id: 'uid3',
            language: 'go',
            ide_name: 'VSCode',
            suggestion_size: 100
          }.to_json
        },
        {
          user_id: 2,
          event: 2,
          timestamp: Time.zone.parse('2023-01-20 09:00:30 UTC'),
          namespace_path: 'group2/project2',
          extras: {
            unique_tracking_id: 'uid3',
            language: 'go',
            suggestion_size: 120
          }.to_json
        },
        {
          user_id: 2,
          event: 3,
          timestamp: Time.zone.parse('2023-01-20 09:01:00 UTC'),
          namespace_path: 'group2/project2',
          extras: {
            unique_tracking_id: 'uid3',
            language: 'go',
            suggestion_size: 120
          }.to_json
        },
        {
          user_id: 2,
          event: 3,
          timestamp: Time.zone.parse('2023-01-20 09:02:00 UTC'),
          namespace_path: 'group2/project2',
          extras: {
            unique_tracking_id: 'uid3',
            language: 'go',
            suggestion_size: 120
          }.to_json
        },
        {
          user_id: 2,
          event: 4,
          timestamp: Time.zone.parse('2023-01-20 09:03:00 UTC'),
          namespace_path: 'group2/project2',
          extras: {
            unique_tracking_id: 'uid3',
            language: 'go',
            suggestion_size: 120
          }.to_json
        },
        {
          user_id: 2,
          event: 4,
          timestamp: Time.zone.parse('2023-01-20 09:04:00 UTC'),
          namespace_path: 'group2/project2',
          extras: {
            unique_tracking_id: 'uid3',
            language: 'go',
            suggestion_size: 120
          }.to_json
        },
        {
          user_id: 3,
          event: 2,
          timestamp: Time.zone.parse('2024-02-10 14:00:00 UTC'),
          namespace_path: 'group3/project3',
          extras: {
            unique_tracking_id: 'uid4',
            language: 'javascript',
            ide_name: 'Neovim',
            suggestion_size: 75
          }.to_json
        }
      ])
    end

    it 'migrates data in batches correctly' do
      migration.up

      results = connection.select(
        <<~SQL
          SELECT
            uid,
            namespace_path,
            user_id,
            language,
            branch_name,
            ide_name,
            ide_vendor,
            ide_version,
            extension_name,
            extension_version,
            language_server_version,
            model_name,
            model_engine,
            suggestion_size,
            minIfMerge(shown_at) as shown_at,
            maxIfMerge(accepted_at) as accepted_at,
            maxIfMerge(rejected_at) as rejected_at
          FROM ai_code_suggestions
          GROUP BY ALL
          ORDER BY uid ASC
        SQL
      )

      expect(results[0]).to include(
        'uid' => 'uid1',
        'namespace_path' => 'group1/project1',
        'user_id' => 1,
        'language' => 'ruby',
        'branch_name' => 'main',
        'ide_name' => 'VSCode',
        'ide_vendor' => 'Microsoft',
        'ide_version' => '1.80.0',
        'extension_name' => 'GitLab Workflow',
        'extension_version' => '3.0.0',
        'language_server_version' => '1.0.0',
        'model_name' => 'claude',
        'model_engine' => 'anthropic',
        'suggestion_size' => 50,
        'shown_at' => Time.zone.parse('2023-01-15 10:00:00 UTC'),
        'accepted_at' => Time.zone.parse('2023-01-15 10:01:00 UTC'),
        'rejected_at' => nil
      )

      expect(results[1]).to include(
        'uid' => 'uid2',
        'namespace_path' => 'group1/project1',
        'user_id' => 1,
        'language' => 'python',
        'branch_name' => 'feature',
        'ide_name' => 'JetBrains',
        'suggestion_size' => 30,
        'shown_at' => Time.zone.parse('2023-01-15 11:00:00 UTC'),
        'accepted_at' => nil,
        'rejected_at' => Time.zone.parse('2023-01-15 11:02:00 UTC')
      )

      expect(results[2]).to include(
        'uid' => 'uid3',
        'namespace_path' => 'group2/project2',
        'user_id' => 2,
        'language' => 'go',
        'ide_name' => 'VSCode',
        'suggestion_size' => 120,
        'shown_at' => Time.zone.parse('2023-01-20 09:00:00 UTC'),
        'accepted_at' => Time.zone.parse('2023-01-20 09:02:00 UTC'),
        'rejected_at' => Time.zone.parse('2023-01-20 09:04:00 UTC')
      )

      expect(results[3]).to include(
        'uid' => 'uid4',
        'namespace_path' => 'group3/project3',
        'user_id' => 3,
        'language' => 'javascript',
        'ide_name' => 'Neovim',
        'suggestion_size' => 75,
        'shown_at' => Time.zone.parse('2024-02-10 14:00:00 UTC'),
        'accepted_at' => nil,
        'rejected_at' => nil
      )
    end
  end

  context 'when there is no data' do
    it 'completes without errors' do
      expect { migration.up }.not_to raise_error
    end

    it 'leaves the target table empty' do
      migration.up

      count = connection.select('SELECT count() FROM ai_code_suggestions').first['count()']
      expect(count).to eq(0)
    end
  end
end
