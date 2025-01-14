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
end
