# frozen_string_literal: true

RSpec.describe Bitbucket::ApiConnection do
  let(:logger) { instance_double(Logger, info: nil) }
  let(:http_client) { class_double(HTTParty) }

  describe '#get' do
    subject(:connection) do
      described_class.new(
        { email: 'user@example.com', api_token: 'token123', logger: logger },
        http_client: http_client
      )
    end

    it 'performs a GET request through the injected http_client with basic auth' do
      expect(connection).to receive(:retry_with_exponential_backoff).and_call_original

      expect(http_client)
        .to receive(:get)
        .with(
          'https://api.bitbucket.org/2.0/user',
          {
            basic_auth: { username: 'user@example.com', password: 'token123' },
            headers: { 'Accept' => 'application/json' },
            query: { page: 1 }
          }
        )
        .and_return(
          instance_double(HTTParty::Response, code: 200, success?: true, parsed_response: {})
        )

      connection.get('/user', page: 1)
    end

    it 'logs the retries and raises an error if it does not succeed on retry' do
      httparty_response = instance_double(Net::HTTPResponse, code: '429')
      allow(http_client).to receive(:get).and_raise(HTTParty::ResponseError.new(httparty_response))
      stub_const('Bitbucket::ExponentialBackoff::INITIAL_DELAY', 0.0)
      allow(Random).to receive(:rand).and_return(0.001)

      expect(logger).to receive(:info)
        .with(message: /Retrying in .+ seconds due to/)
        .twice

      expect { connection.get('/users') }.to raise_error(Bitbucket::ExponentialBackoff::RateLimitError)
    end
  end

  describe 'http_client requirement' do
    it 'raises ArgumentError when no http_client is provided' do
      expect { described_class.new({ email: 'user@example.com', api_token: 'token123' }) }
        .to raise_error(ArgumentError, /missing keyword: :http_client/)
    end
  end

  describe 'null logger fallback' do
    subject(:connection) do
      described_class.new({ email: 'user@example.com', api_token: 'token123' }, http_client: http_client)
    end

    it 'does not raise when no logger is injected and a retry fires' do
      httparty_response = instance_double(Net::HTTPResponse, code: '429')
      allow(http_client).to receive(:get).and_raise(HTTParty::ResponseError.new(httparty_response))
      stub_const('Bitbucket::ExponentialBackoff::INITIAL_DELAY', 0.0)
      allow(Random).to receive(:rand).and_return(0.001)

      expect { connection.get('/user') }.to raise_error(Bitbucket::ExponentialBackoff::RateLimitError)
    end
  end

  describe '#get_response_code' do
    subject(:connection) do
      described_class.new({ email: 'user@example.com', api_token: 'token123' }, http_client: http_client)
    end

    it 'returns the HTTP status code as an integer' do
      expect(http_client)
        .to receive(:get)
        .and_return(instance_double(HTTParty::Response, code: 404, success?: false, parsed_response: {}))

      expect(connection.get_response_code('/repositories/workspace/repo/issues')).to eq(404)
    end
  end

  describe '#refresh_if_expired!' do
    subject(:connection) do
      described_class.new({ email: 'user@example.com', api_token: 'token123' }, http_client: http_client)
    end

    it 'is a no-op because API token credentials do not expire' do
      expect(connection.refresh_if_expired!).to be_nil
    end
  end
end
