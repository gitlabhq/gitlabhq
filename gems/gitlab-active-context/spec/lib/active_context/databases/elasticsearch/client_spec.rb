# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Elasticsearch::Client do
  let(:options) { { url: 'http://localhost:9200' } }

  subject(:client) { described_class.new(options) }

  describe '#search' do
    let(:user) { double }
    let(:collection) { double }
    let(:elasticsearch_client) { instance_double(Elasticsearch::Client) }
    let(:search_response) do
      hits = [1, 2, 3].map { |id| { '_source' => { 'id' => id } } }

      { 'hits' => { 'hits' => hits } }
    end

    let(:query) { ActiveContext::Query.filter(project_id: 1) }

    before do
      allow(client).to receive(:client).and_return(elasticsearch_client)
      allow(elasticsearch_client).to receive(:search).and_return(search_response)
      allow(collection).to receive_messages(collection_name: 'test', redact_unauthorized_results!: [[], []])
    end

    it 'calls search on the Elasticsearch client without _source by default' do
      expect(elasticsearch_client).to receive(:search).with(
        index: 'test',
        body: hash_not_including(:_source)
      )
      client.search(collection: collection, query: query, user: user)
    end

    context 'when source_fields is provided' do
      it 'includes _source with the specified fields' do
        expect(elasticsearch_client).to receive(:search).with(
          index: 'test',
          body: hash_including(_source: { includes: ['content'] })
        )
        client.search(collection: collection, query: query, user: user, source_fields: ['content'])
      end
    end

    it 'logs search duration and result count' do
      expect(ActiveContext::Logger).to receive(:info).with(
        message: 'ActiveContext client search completed',
        collection: collection,
        duration_s: be_a(Float),
        result_count: 3
      )

      client.search(collection: collection, query: query, user: user)
    end
  end

  describe '#client' do
    it 'returns an instance of Elasticsearch::Client' do
      expect(Elasticsearch::Client).to receive(:new).with(client.send(:elasticsearch_config)).and_call_original

      expect(client.client).to be_a(Elasticsearch::Client)
    end

    it 'memoizes the Elasticsearch::Client instance' do
      expect(Elasticsearch::Client).to receive(:new).once.and_call_original

      raw_client = client.client

      expect(client.client).to be(raw_client)
    end

    context 'when client_adapter option is set' do
      let(:options) { { url: 'http://localhost:9200', client_request_timeout: 30, client_adapter: 'net_http' } }

      it 'uses the given adapter' do
        transport_options = client.client.transport.options

        expect(transport_options).to include(adapter: :net_http)
      end
    end

    context 'when client_adapter option is nil' do
      let(:options) { { url: 'http://localhost:9200', client_request_timeout: 30, client_adapter: nil } }

      it 'falls back to the DEFAULT_ADAPTER' do
        transport_options = client.client.transport.options

        expect(transport_options).to include(adapter: described_class::DEFAULT_ADAPTER)
      end
    end
  end

  describe '#elasticsearch_config' do
    let(:options) { { url: 'http://localhost:9200', client_request_timeout: 30, retry_on_failure: 3, debug: true } }

    it 'returns the expected configuration hash' do
      config = client.send(:elasticsearch_config)

      expect(config).to include(
        adapter: described_class::DEFAULT_ADAPTER,
        urls: options[:url],
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
  end
end
