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
      allow(collection).to receive_messages(collection_name: 'test', redact_unauthorized_results!: [[], []])
    end

    it 'calls search on the Elasticsearch client' do
      expect(elasticsearch_client).to receive(:search)
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
        adapter: :typhoeus,
        urls: 'http://localhost:9200',
        transport_options: {
          request: {
            timeout: 30,
            open_timeout: 5
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
