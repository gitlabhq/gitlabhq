# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Postgresql::Adapter do
  let(:connection) { double('Connection') }
  let(:options) do
    {
      host: 'localhost',
      port: 5432,
      database: 'test_db',
      user: 'user',
      password: 'pass'
    }
  end

  subject(:adapter) { described_class.new(connection, options: options) }

  it 'delegates search to client' do
    query = ActiveContext::Query.filter(foo: :bar)
    expect(adapter.client).to receive(:search).with(query)

    adapter.search(query)
  end

  describe '#prefix' do
    it 'returns default prefix when not specified' do
      expect(adapter.prefix).to eq('gitlab_active_context')
    end

    it 'returns configured prefix' do
      adapter = described_class.new(connection, options: options.merge(prefix: 'custom'))
      expect(adapter.prefix).to eq('custom')
    end
  end

  describe '#indexer_connection_options' do
    it 'returns connection options for indexer' do
      result = adapter.indexer_connection_options

      expect(result).to eq(
        host: 'localhost',
        port: 5432,
        database: 'test_db',
        user: 'user',
        password: 'pass'
      )
    end

    it 'includes only essential connection keys' do
      result = adapter.indexer_connection_options

      expect(result.keys).to contain_exactly(:host, :port, :user, :password, :database)
    end
  end
end
