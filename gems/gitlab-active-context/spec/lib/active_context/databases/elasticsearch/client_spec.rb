# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Elasticsearch::Client do
  let(:options) { { url: 'http://localhost:9200' } }
  let(:user) { double }
  let(:collection) { double }

  subject(:client) { described_class.new(options) }

  describe '#search' do
    let(:elasticsearch_client) { instance_double(Elasticsearch::Client) }
    let(:search_response) { { 'hits' => { 'total' => 5, 'hits' => [] } } }
    let(:query) { ActiveContext::Query.filter(project_id: 1) }

    before do
      allow(client).to receive(:client).and_return(elasticsearch_client)
      allow(elasticsearch_client).to receive(:search).and_return(search_response)
      allow(collection).to receive_messages(
        collection_name: 'test',
        redact_unauthorized_results!: [[], []],
        current_embedding_fields: %w[embedding_v1 embedding_v2]
      )
    end

    it 'calls search on the Elasticsearch client' do
      expect(elasticsearch_client).to receive(:search).with(
        index: 'test',
        body: hash_including(_source: { includes: ['*', 'embedding_v1', 'embedding_v2'] })
      )
      client.search(collection: collection, query: query, user: user)
    end
  end

  describe '#client' do
    let(:elasticsearch_config) { client.send(:elasticsearch_config) }
    let(:options) { { url: 'http://localhost:9200', client_request_timeout: 30, retry_on_failure: 3, debug: true } }

    it 'returns an instance of Elasticsearch::Client' do
      expect(Elasticsearch::Client).to receive(:new).with(elasticsearch_config)
      client.client
    end

    it 'includes all expected keys with correct values' do
      expect(elasticsearch_config).to include(
        adapter: described_class::DEFAULT_ADAPTER,
        urls: 'http://localhost:9200',
        transport_options: {
          request: {
            timeout: 30,
            open_timeout: described_class::OPEN_TIMEOUT
          }
        },
        randomize_hosts: true,
        retry_on_failure: 3,
        log: true,
        debug: true
      )
    end

    context 'when adapter is set in elasticsearch_config' do
      let(:options) { { url: 'http://localhost:9200', client_request_timeout: 30, client_adapter: 'net_http' } }

      it 'uses the adapter from elasticsearch_config' do
        options = client.client.transport.options

        expect(options).to include(adapter: :net_http)
      end
    end

    context 'when client_adapter in elasticsearch_config is null' do
      let(:options) { { url: 'http://localhost:9200', client_request_timeout: 30, client_adapter: nil } }

      it 'falls back to the DEFAULT_ADAPTER' do
        options = client.client.transport.options

        expect(options).to include(adapter: described_class::DEFAULT_ADAPTER)
      end
    end
  end
end
