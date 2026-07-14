# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BitbucketServer::Connection do
  let(:http_client) { class_double(HTTParty) }
  let(:logger) { instance_double(Logger, info: nil) }
  let(:options) { { base_uri: 'https://test:7990', user: 'bitbucket', password: 'mypassword', logger: logger } }
  let(:payload) { { 'test' => 1 } }
  let(:url) { 'https://test:7990/rest/api/1.0/test?something=1' }
  let(:auth) { { username: 'bitbucket', password: 'mypassword' } }
  let(:accept_headers) { { 'Accept' => 'application/json' } }
  let(:post_headers) { accept_headers.merge('Content-Type' => 'application/json') }

  # Build a fake HTTParty response double for use across tests
  def ok_response(body = payload)
    instance_double(HTTParty::Response,
      code: 200,
      headers: {},
      parsed_response: body)
  end

  def error_response(code, body = payload)
    instance_double(HTTParty::Response,
      code: code,
      headers: {},
      parsed_response: body)
  end

  subject { described_class.new(options, http_client: http_client) }

  describe '#get' do
    before do
      allow(http_client).to receive(:get)
        .with(url, hash_including(basic_auth: auth, headers: accept_headers))
        .and_return(ok_response)
    end

    it 'runs with retry_with_delay' do
      expect(subject).to receive(:retry_with_delay).and_call_original.once

      subject.get(url)
    end

    it 'returns JSON body' do
      expect(subject.get(url, { something: 1 })).to eq(payload)
    end

    it 'throws an exception if the response is not 200' do
      allow(http_client).to receive(:get).and_return(error_response(500))

      expect { subject.get(url) }.to raise_error(described_class::ConnectionError)
    end

    it 'includes the HTTP status code in the ConnectionError' do
      body_with_error = { 'errors' => [{ 'message' => 'Not Found' }] }
      allow(http_client).to receive(:get).and_return(error_response(404, body_with_error))

      expect { subject.get(url) }.to raise_error(described_class::ConnectionError) do |error|
        expect(error.http_status_code).to eq(404)
      end
    end

    it 'sets http_status_code to nil for non-HTTP errors' do
      allow(http_client).to receive(:get).and_raise(OpenSSL::SSL::SSLError)

      expect { subject.get(url) }.to raise_error(described_class::ConnectionError) do |error|
        expect(error.http_status_code).to be_nil
      end
    end
  end

  describe 'ConnectionError#retryable?' do
    using RSpec::Parameterized::TableSyntax

    where(:status_code, :expected_retryable) do
      nil | true
      401 | false
      403 | false
      404 | false
      410 | false
      408 | true
      429 | true
      500 | true
      502 | true
      503 | true
      599 | true
      600 | false
    end

    with_them do
      it 'returns the expected value' do
        error = described_class::ConnectionError.new('test', http_status_code: status_code)
        expect(error.retryable?).to eq(expected_retryable)
      end
    end

    it 'throws an exception if the response is not JSON' do
      non_json = instance_double(HTTParty::Response, code: 200, headers: {}, parsed_response: 'bad data')
      allow(http_client).to receive(:get).and_return(non_json)

      expect { subject.get(url) }.to raise_error(described_class::ConnectionError)
    end

    it 'raises JSON::NestingError as is' do
      response = instance_double(HTTParty::Response, code: 200)

      allow(response).to receive(:parsed_response).and_raise(JSON::NestingError)
      allow(http_client).to receive(:get).and_return(response)

      expect { subject.get(url, { something: 1 }) }.to raise_error(JSON::NestingError)
    end

    it 'throws an exception upon a network error' do
      allow(http_client).to receive(:get).and_raise(OpenSSL::SSL::SSLError)

      expect { subject.get(url) }.to raise_error(described_class::ConnectionError)
    end

    context 'when the response is a 429 rate limit reached error' do
      let(:response) do
        instance_double(HTTParty::Response, parsed_response: payload, code: 429,
          headers: { 'retry-after' => '0' })
      end

      before do
        allow(http_client).to receive(:get).and_return(response)
      end

      it 'sleeps, retries and if the error persists it fails' do
        expect(logger).to receive(:info)
          .with(message: 'Retrying in 0 seconds due to 429 Too Many Requests')
          .once

        expect { subject.get(url) }.to raise_error(BitbucketServer::Connection::ConnectionError)
      end
    end
  end

  describe '#post' do
    before do
      allow(http_client).to receive(:post)
        .with(url, hash_including(basic_auth: auth, headers: post_headers, body: payload))
        .and_return(ok_response)
    end

    it 'runs with retry_with_delay' do
      expect(subject).to receive(:retry_with_delay).and_call_original.once

      subject.post(url, payload)
    end

    it 'returns JSON body' do
      expect(subject.post(url, payload)).to eq(payload)
    end

    it 'throws an exception if the response is not 200' do
      allow(http_client).to receive(:post).and_return(error_response(500))

      expect { subject.post(url, payload) }.to raise_error(described_class::ConnectionError)
    end

    it 'throws an exception upon a network error' do
      allow(http_client).to receive(:post).and_raise(OpenSSL::SSL::SSLError)

      expect { subject.post(url, payload) }.to raise_error(described_class::ConnectionError)
    end

    it 'throws an exception if the URI is invalid' do
      allow(http_client).to receive(:post).and_raise(URI::InvalidURIError)

      expect { subject.post(url, payload) }.to raise_error(described_class::ConnectionError)
    end
  end

  describe '#delete' do
    let(:branch_path) { '/projects/foo/repos/bar/branches' }
    let(:branch_url) { 'https://test:7990/rest/branch-utils/1.0/projects/foo/repos/bar/branches' }

    before do
      allow(http_client).to receive(:delete)
        .with(branch_url, hash_including(basic_auth: auth, headers: post_headers, body: payload))
        .and_return(ok_response)
    end

    context 'when deleting a branch resource' do
      it 'runs with retry_with_delay' do
        expect(subject).to receive(:retry_with_delay).and_call_original.once

        subject.delete(:branches, branch_path, payload)
      end

      it 'returns JSON body' do
        expect(subject.delete(:branches, branch_path, payload)).to eq(payload)
      end

      it 'throws an exception if the response is not 200' do
        allow(http_client).to receive(:delete).and_return(error_response(500))

        expect { subject.delete(:branches, branch_path, payload) }.to raise_error(described_class::ConnectionError)
      end

      it 'throws an exception upon a network error' do
        allow(http_client).to receive(:delete).and_raise(OpenSSL::SSL::SSLError)

        expect { subject.delete(:branches, branch_path, payload) }.to raise_error(described_class::ConnectionError)
      end
    end
  end

  describe 'http_client requirement' do
    it 'raises ArgumentError when no http_client is provided' do
      expect { described_class.new(options) }
        .to raise_error(ArgumentError, /missing keyword: :http_client/)
    end

    it 'sends requests through the injected http_client' do
      expect(http_client).to receive(:get).and_return(ok_response)

      subject.get(url)
    end
  end
end
