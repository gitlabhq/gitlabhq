# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Opensearch::Client do
  let(:options) { { url: 'http://localhost:9200' } }
  let(:user) { double }
  let(:collection) { double }

  subject(:client) { described_class.new(options) }

  describe '#search' do
    let(:opensearch_client) { instance_double(OpenSearch::Client) }
    let(:search_response) { { 'hits' => { 'total' => 5, 'hits' => [] } } }
    let(:query) { ActiveContext::Query.filter(project_id: 1) }

    before do
      allow(client).to receive(:client).and_return(opensearch_client)
      allow(opensearch_client).to receive(:search).and_return(search_response)
      allow(collection).to receive_messages(collection_name: 'test', redact_unauthorized_results!: [[], []])
    end

    it 'calls search on the Opensearch client' do
      expect(opensearch_client).to receive(:search)
      client.search(collection: collection, query: query, user: user)
    end
  end

  describe '#client' do
    it 'returns an instance of OpenSearch::Client' do
      expect(OpenSearch::Client).to receive(:new).with(client.send(:opensearch_config))
      client.client
    end
  end

  describe '#opensearch_config' do
    let(:options) { { url: 'http://localhost:9200', client_request_timeout: 45, retry_on_failure: 5, debug: true } }

    it 'returns expected configuration hash' do
      config = client.send(:opensearch_config)

      expect(config).to include(
        adapter: described_class::DEFAULT_ADAPTER,
        urls: options[:url],
        transport_options: {
          request: {
            timeout: 45,
            open_timeout: described_class::OPEN_TIMEOUT
          }
        },
        randomize_hosts: true,
        retry_on_failure: 5,
        log: true,
        debug: true
      )
    end

    context 'when adapter is set in elasticsearch_config' do
      let(:options) { { url: 'http://localhost:9200', client_request_timeout: 30, client_adapter: 'net_http' } }

      it 'uses the adapter from elasticsearch_config' do
        options = client.client.transport.transport.options

        expect(options).to include(adapter: :net_http)
      end
    end

    context 'when client_adapter in elasticsearch_config is null' do
      let(:options) { { url: 'http://localhost:9200', client_request_timeout: 30, client_adapter: nil } }

      it 'falls back to the DEFAULT_ADAPTER' do
        options = client.client.transport.transport.options

        expect(options).to include(adapter: described_class::DEFAULT_ADAPTER)
      end
    end
  end

  describe '#aws_credentials' do
    context 'when static credentials are provided' do
      let(:options) do
        {
          url: 'http://localhost:9200',
          aws: true,
          aws_access_key: 'access_key',
          aws_secret_access_key: 'secret_key'
        }
      end

      it 'returns static credentials' do
        credentials = client.aws_credentials
        expect(credentials).to be_a(Aws::Credentials)
        expect(credentials.access_key_id).to eq('access_key')
        expect(credentials.secret_access_key).to eq('secret_key')
      end
    end

    context 'when static credentials are not provided' do
      let(:options) { { url: 'http://localhost:9200', aws: true } }
      let(:mock_provider) { instance_double(Aws::Credentials, set?: true) }
      let(:mock_chain) { instance_double(Aws::CredentialProviderChain, resolve: mock_provider) }

      before do
        allow(Aws::CredentialProviderChain).to receive(:new).and_return(mock_chain)
      end

      it 'uses the AWS credential provider chain' do
        expect(client.aws_credentials).to eq(mock_provider)
      end
    end

    context 'when no valid credentials are found' do
      let(:options) { { url: 'http://localhost:9200', aws: true } }
      let(:mock_chain) { instance_double(Aws::CredentialProviderChain, resolve: nil) }

      before do
        allow(Aws::CredentialProviderChain).to receive(:new).and_return(mock_chain)
      end

      it 'returns nil' do
        expect(client.aws_credentials).to be_nil
      end
    end
  end
end
