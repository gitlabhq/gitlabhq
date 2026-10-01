# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Opensearch::Client do
  let(:options) { { url: 'http://localhost:9200' } }

  subject(:client) { described_class.new(options) }

  describe '#search' do
    let(:user) { double }
    let(:collection) { double }
    let(:opensearch_client) { instance_double(OpenSearch::Client) }
    let(:search_response) do
      hits = [1, 2, 3].map { |id| { '_source' => { 'id' => id } } }

      { 'hits' => { 'hits' => hits } }
    end

    let(:query) { ActiveContext::Query.filter(project_id: 1) }

    before do
      allow(client).to receive(:client).and_return(opensearch_client)
      allow(opensearch_client).to receive(:search).and_return(search_response)
      allow(collection).to receive_messages(collection_name: 'test', redact_unauthorized_results!: [[], []])
    end

    it 'calls search on the OpenSearch client without _source by default' do
      expect(opensearch_client).to receive(:search).with(
        index: 'test',
        body: hash_not_including(:_source)
      )
      client.search(collection: collection, query: query, user: user)
    end

    context 'when source_fields is provided' do
      it 'includes _source with the specified fields' do
        expect(opensearch_client).to receive(:search).with(
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
    it 'returns an instance of OpenSearch::Client' do
      expect(OpenSearch::Client).to receive(:new).with(client.send(:opensearch_config)).and_call_original

      expect(client.client).to be_a(OpenSearch::Client)
    end

    it 'memoizes the OpenSearch::Client instance' do
      expect(OpenSearch::Client).to receive(:new).once.and_call_original

      raw_client = client.client

      expect(client.client).to be(raw_client)
    end

    context 'when client_adapter option is set' do
      let(:options) { { url: 'http://localhost:9200', client_request_timeout: 30, client_adapter: 'net_http' } }

      it 'uses the given adapter' do
        transport_options = client.client.transport.transport.options

        expect(transport_options).to include(adapter: :net_http)
      end
    end

    context 'when client_adapter option is nil' do
      let(:options) { { url: 'http://localhost:9200', client_request_timeout: 30, client_adapter: nil } }

      it 'falls back to the DEFAULT_ADAPTER' do
        transport_options = client.client.transport.transport.options

        expect(transport_options).to include(adapter: described_class::DEFAULT_ADAPTER)
      end
    end

    context 'when AWS is enabled' do
      let(:options) { { url: 'http://localhost:9200', aws: true } }
      let(:credentials) { Aws::Credentials.new('access_key', 'secret_key') }
      let(:chain) { instance_double(Aws::CredentialProviderChain, resolve: credentials) }

      before do
        allow(Aws::CredentialProviderChain).to receive(:new).and_return(chain)
      end

      it 'resolves AWS credentials once across calls' do
        2.times { client.client }

        expect(chain).to have_received(:resolve).once
      end

      context 'when AWS credentials cannot be resolved' do
        before do
          allow(chain).to receive(:resolve).and_return(nil, credentials)
        end

        it 'raises and builds a new client on the next call', :aggregate_failures do
          expect { client.client }.to raise_error(Aws::Sigv4::Errors::MissingCredentialsError)
          expect(client.client).to be_a(OpenSearch::Client)
          expect(chain).to have_received(:resolve).twice
        end
      end
    end
  end

  describe '#opensearch_config' do
    let(:options) { { url: 'http://localhost:9200', client_request_timeout: 30, retry_on_failure: 3, debug: true } }

    it 'returns the expected configuration hash' do
      config = client.send(:opensearch_config)

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

      it 'returns static credentials', :aggregate_failures do
        credentials = client.aws_credentials

        expect(credentials).to be_a(Aws::Credentials)
        expect(credentials.access_key_id).to eq('access_key')
        expect(credentials.secret_access_key).to eq('secret_key')
      end
    end

    context 'when static credentials are not provided' do
      let(:options) { { url: 'http://localhost:9200', aws: true } }
      let(:credentials) { instance_double(Aws::Credentials, set?: true) }
      let(:chain) { instance_double(Aws::CredentialProviderChain, resolve: credentials) }

      before do
        allow(Aws::CredentialProviderChain).to receive(:new).and_return(chain)
      end

      it 'uses the AWS credential provider chain' do
        expect(client.aws_credentials).to eq(credentials)
      end
    end

    context 'when no valid credentials are found' do
      let(:options) { { url: 'http://localhost:9200', aws: true } }
      let(:chain) { instance_double(Aws::CredentialProviderChain, resolve: nil) }

      before do
        allow(Aws::CredentialProviderChain).to receive(:new).and_return(chain)
      end

      it 'returns nil' do
        expect(client.aws_credentials).to be_nil
      end
    end
  end
end
