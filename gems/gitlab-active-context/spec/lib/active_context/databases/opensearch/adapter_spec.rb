# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Opensearch::Adapter do
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
      options = adapter.client.client.transport.transport.options

      expect(options).to include(adapter: ActiveContext::Databases::Opensearch::Client::DEFAULT_ADAPTER)
    end

    it 'uses the specified adapter' do
      adapter = described_class.new(connection, options: options.merge(client_adapter: :net_http))
      options = adapter.client.client.transport.transport.options

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
    it 'returns normalized URLs with AWS options' do
      adapter = described_class.new(connection, options: {
        url: [{ scheme: 'https', host: 'search-test.us-east-1.es.amazonaws.com', port: 443 }],
        aws: true,
        aws_region: 'us-east-1',
        aws_access_key: '********************',
        aws_secret_access_key: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
        client_request_timeout: 60
      })

      result = adapter.indexer_connection_options

      expect(result).to eq(
        url: ['https://search-test.us-east-1.es.amazonaws.com/'],
        aws: true,
        aws_region: 'us-east-1',
        aws_access_key: '********************',
        aws_secret_access_key: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
        client_request_timeout: 60
      )
    end

    it 'returns only URL when AWS is not enabled' do
      adapter = described_class.new(connection, options: {
        url: 'https://localhost:9200',
        aws_region: 'us-east-1'
      })

      result = adapter.indexer_connection_options

      expect(result).to eq(url: ['https://localhost:9200'])
    end

    it 'filters out nil AWS options' do
      adapter = described_class.new(connection, options: {
        url: 'https://localhost:9200',
        aws: true,
        aws_region: 'us-east-1',
        aws_access_key: nil
      })

      result = adapter.indexer_connection_options

      expect(result).to eq(
        url: ['https://localhost:9200'],
        aws: true,
        aws_region: 'us-east-1'
      )
    end

    it 'includes aws_role_arn when provided' do
      adapter = described_class.new(connection, options: {
        url: 'https://localhost:9200',
        aws: true,
        aws_role_arn: 'arn:aws:iam::123456789012:role/MyRole'
      })

      result = adapter.indexer_connection_options

      expect(result).to eq(
        url: ['https://localhost:9200'],
        aws: true,
        aws_role_arn: 'arn:aws:iam::123456789012:role/MyRole'
      )
    end
  end
end
