# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Elasticsearch::Adapter do
  let(:connection) { double('Connection') }
  let(:options) { { url: 'http://localhost:9200' } }

  subject(:adapter) { described_class.new(connection, options: options) }

  it 'delegates search to client' do
    query = ActiveContext::Query.filter(foo: :bar)
    expect(adapter.client).to receive(:search).with(query)

    adapter.search(query)
  end

  describe '#adapter' do
    it 'uses the default adapter if not specified' do
      options = adapter.client.client.transport.options

      expect(options).to include(adapter: ActiveContext::Databases::Elasticsearch::Client::DEFAULT_ADAPTER)
    end

    it 'uses the specified adapter' do
      adapter = described_class.new(connection, options: options.merge(client_adapter: :net_http))
      options = adapter.client.client.transport.options

      expect(options).to include(adapter: :net_http)
    end
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
    it 'returns normalized URLs' do
      adapter = described_class.new(connection, options: {
        url: [
          { scheme: 'http', host: 'localhost', port: 9200 },
          { scheme: 'https', host: 'example.com', port: 9200 }
        ]
      })

      result = adapter.indexer_connection_options

      expect(result).to eq(url: ['http://localhost:9200/', 'https://example.com:9200/'])
    end

    it 'handles string URLs' do
      adapter = described_class.new(connection, options: { url: ['http://localhost:9200', 'http://localhost:9201'] })

      result = adapter.indexer_connection_options

      expect(result).to eq(url: ['http://localhost:9200', 'http://localhost:9201'])
    end

    it 'handles single URL' do
      adapter = described_class.new(connection, options: { url: 'http://localhost:9200' })

      result = adapter.indexer_connection_options

      expect(result).to eq(url: ['http://localhost:9200'])
    end
  end
end
