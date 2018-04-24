# encoding: utf-8

require 'spec_helper'
require Rails.root.join('ee', 'db', 'post_migrate', '20180417102933_drop_repository_storage_events_for_geo_events.rb')

describe DropRepositoryStorageEventsForGeoEvents, :migration do
  let(:migration) { described_class.new }

  describe '#up' do
    before do
      migration.up
    end

    it 'dropped the repository_storage_path column' do
      described_class::TABLES.each do |table_name|
        columns = table(table_name).columns.map(&:name)

        expect(columns).not_to include("repository_storage_path")
      end
    end
  end

  describe '#down' do
    let(:event_name) { :geo_repository_created_event }

    before do
      described_class.const_set(:BATCH_SIZE, 1)

      Gitlab.config.repositories.storages.each do |name, _|
        described_class.execute(<<~SQL
                                INSERT INTO #{event_name}s (project_id, project_name, repository_storage_name, repo_path)
                                VALUES (1, 'mepmep', '#{name}', 'path/to/gitlab-org')
                                SQL
                               )
      end

      migration.down
      reset_column_in_all_models
    end

    it 'created the repository_storage_path column' do
      described_class::TABLES.each do |table_name|
        columns = table(table_name).columns.map(&:name)

        expect(columns).to include("repository_storage_path")
      end

      null_columns = described_class
        .execute("SELECT COUNT(*) FROM #{event_name}s WHERE repository_storage_path IS NULL;")
        .first['count']

      expect(null_columns.to_i).to be(0)
    end
  end
end
