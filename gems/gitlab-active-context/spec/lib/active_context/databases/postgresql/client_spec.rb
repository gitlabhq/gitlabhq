# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Postgresql::Client do
  let(:options) do
    {
      host: 'localhost',
      port: 5432,
      database: 'test_db',
      username: 'user',
      password: 'pass',
      pool_size: 2,
      pool_timeout: 1
    }
  end

  subject(:client) { described_class.new(options) }

  describe '#initialize' do
    it 'creates a connection pool' do
      expect(ConnectionPool).to receive(:new)
        .with(hash_including(size: 2, timeout: 1))

      client
    end
  end

  describe '#search' do
    let(:connection) { instance_double(PG::Connection) }
    let(:query_result) { instance_double(PG::Result) }

    before do
      allow(PG).to receive(:connect).and_return(connection)
      allow(connection).to receive(:exec).and_return(query_result)
    end

    it 'executes query and returns QueryResult' do
      expect(connection).to receive(:exec).with('SELECT * FROM pg_stat_activity')
      expect(ActiveContext::Databases::Postgresql::QueryResult)
        .to receive(:new).with(query_result)

      client.search('test query')
    end
  end

  describe '#prefix' do
    it 'returns default prefix when not specified' do
      expect(client.prefix).to eq('gitlab_active_context')
    end

    it 'returns configured prefix' do
      client = described_class.new(options.merge(prefix: 'custom'))
      expect(client.prefix).to eq('custom')
    end
  end
end
