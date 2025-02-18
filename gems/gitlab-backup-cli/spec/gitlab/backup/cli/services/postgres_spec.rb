# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::Services::Postgres do
  let(:context) { build_test_context }

  subject(:postgres) { described_class.new(context) }

  describe '#entries' do
    context 'with missing database configuration' do
      it 'raises an error' do
        allow(context).to receive(:database_config_file_path).and_return('/tmp/invalid')

        expect { postgres.entries }.to raise_error(Gitlab::Backup::Cli::Errors::DatabaseConfigMissingError)
      end
    end

    it 'returns a collection of Database objects' do
      expect(postgres.entries).to all(be_a(Gitlab::Backup::Cli::Services::Database))
    end
  end

  describe '#each' do
    it 'returns an enumerator when no block is given' do
      expect(postgres.each).to be_an(Enumerator)
      expect(postgres.each.map).to all(be_a(Gitlab::Backup::Cli::Services::Database))
    end

    it 'yields a collection of database objects' do
      expect { |b| postgres.each(&b) }.to yield_successive_args(*postgres.entries)
    end
  end

  describe '#main_database' do
    it 'returns a Database object for the main configuration entry' do
      main_database = postgres.entries.find { |e| e.connection_name == 'main' }

      expect(postgres.main_database).to be_an(Gitlab::Backup::Cli::Services::Database)
      expect(postgres.main_database).to eq(main_database)
    end

    context 'with database configuration missing main entry' do
      it 'raises an error' do
        database_fixture_path = fixtures_path.join('config/database-different-connection-names.yml')
        allow(context).to receive(:database_config_file_path).and_return(database_fixture_path)

        expect { postgres.main_database }.to raise_error(Gitlab::Backup::Cli::Errors::DatabaseMissingConnectionError)
      end
    end
  end
end
