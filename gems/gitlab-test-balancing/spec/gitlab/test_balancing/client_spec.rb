# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TestBalancing::Client, feature_category: :code_testing do
  let(:api_url) { 'https://gitlab.example.com/api/v4' }
  let(:job_token) { 'job-token-123' }

  subject(:client) { described_class.new(api_url: api_url, job_token: job_token) }

  describe '#initialize_balancing' do
    let(:test_splits) do
      [
        { path: 'spec/models/user_spec.rb', expected_duration: 12.5 },
        { path: 'spec/features/login_spec.rb' }
      ]
    end

    let(:url) { "#{api_url}/job/test_balancing/initialize" }

    it 'posts the test splits with the job token and returns a seed result' do
      stub = stub_request(:post, url)
        .with(
          headers: { 'JOB-TOKEN' => job_token, 'Content-Type' => 'application/json' },
          body: { test_splits: test_splits }.to_json
        )
        .to_return(
          status: 201,
          body: {
            mode: 'seed',
            test_splits: [{ path: 'spec/models/user_spec.rb', expected_duration: 12.5 }]
          }.to_json
        )

      result = client.initialize_balancing(test_splits)

      expect(stub).to have_been_requested
      expect(result.mode).to eq('seed')
      expect(result.test_splits).to eq([{ path: 'spec/models/user_spec.rb', expected_duration: 12.5 }])
    end

    it 'returns a retry result when the node replays a previously claimed set' do
      stub_request(:post, url).to_return(
        status: 201,
        body: {
          mode: 'retry',
          test_splits: [{ path: 'spec/models/user_spec.rb', expected_duration: 12.5 }]
        }.to_json
      )

      result = client.initialize_balancing(test_splits)

      expect(result.mode).to eq('retry')
      expect(result.test_splits).to eq([{ path: 'spec/models/user_spec.rb', expected_duration: 12.5 }])
    end

    it 'raises FeatureUnavailableError on 404' do
      stub_request(:post, url).to_return(status: 404, body: '')

      expect { client.initialize_balancing(test_splits) }
        .to raise_error(described_class::FeatureUnavailableError)
    end

    it 'raises Error on other non-success responses' do
      stub_request(:post, url).to_return(status: 422, body: 'Job is not a parallel job')

      expect { client.initialize_balancing(test_splits) }
        .to raise_error(described_class::Error, /422 Job is not a parallel job/)
    end
  end

  describe '#request' do
    let(:url) { "#{api_url}/job/test_balancing/request" }

    it 'returns the next batch of test splits' do
      stub_request(:post, url)
        .with(headers: { 'JOB-TOKEN' => job_token })
        .to_return(
          status: 201,
          body: { test_splits: [{ path: 'spec/features/login_spec.rb', expected_duration: 210.4 }] }.to_json
        )

      expect(client.request).to eq([{ path: 'spec/features/login_spec.rb', expected_duration: 210.4 }])
    end

    it 'returns an empty array when the queue is drained' do
      stub_request(:post, url).to_return(status: 201, body: { test_splits: [] }.to_json)

      expect(client.request).to eq([])
    end

    it 'raises FeatureUnavailableError on 404' do
      stub_request(:post, url).to_return(status: 404, body: '')

      expect { client.request }.to raise_error(described_class::FeatureUnavailableError)
    end
  end

  describe 'network retries' do
    let(:url) { "#{api_url}/job/test_balancing/request" }

    before do
      allow(client).to receive(:sleep) # don't actually wait between retries
    end

    it 'retries transient network errors and succeeds' do
      stub = stub_request(:post, url)
        .to_raise(Net::ReadTimeout).then
        .to_return(status: 201, body: { test_splits: [] }.to_json)

      expect(client.request).to eq([])
      expect(stub).to have_been_requested.twice
    end

    it 'gives up after MAX_ATTEMPTS and raises Error' do
      stub = stub_request(:post, url).to_raise(Net::ReadTimeout)

      expect { client.request }
        .to raise_error(described_class::Error, a_string_including("after #{described_class::MAX_ATTEMPTS} attempts"))
      expect(stub).to have_been_requested.times(described_class::MAX_ATTEMPTS)
    end

    it 'does not retry HTTP error responses' do
      stub = stub_request(:post, url).to_return(status: 422, body: 'nope')

      expect { client.request }.to raise_error(described_class::Error, /422/)
      expect(stub).to have_been_requested.once
    end

    it 'does not retry a 404 (feature unavailable)' do
      stub = stub_request(:post, url).to_return(status: 404, body: '')

      expect { client.request }.to raise_error(described_class::FeatureUnavailableError)
      expect(stub).to have_been_requested.once
    end
  end

  describe '#net_http_class' do
    # The global spec stub (see spec_helper) forces plain Net::HTTP so WebMock can
    # intercept; call the real implementation here to verify selection logic.
    subject(:net_http_class) { client.send(:net_http_class) }

    before do
      allow(client).to receive(:net_http_class).and_call_original
    end

    context 'when WebMock is loaded' do
      it 'uses the original, un-stubbed Net::HTTP so requests bypass WebMock' do
        expect(net_http_class).to eq(WebMock::HttpLibAdapters::NetHttpAdapter::OriginalNetHTTP)
      end
    end

    context 'when WebMock is not loaded' do
      it 'falls back to plain Net::HTTP' do
        hide_const('WebMock::HttpLibAdapters::NetHttpAdapter::OriginalNetHTTP')

        expect(net_http_class).to eq(Net::HTTP)
      end
    end
  end

  describe 'environment variable defaults' do
    it 'reads the API URL and job token from the environment' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('CI_API_V4_URL').and_return('https://ci.example.com/api/v4')
      allow(ENV).to receive(:[]).with('CI_JOB_TOKEN').and_return('env-token')

      stub = stub_request(:post, 'https://ci.example.com/api/v4/job/test_balancing/request')
        .with(headers: { 'JOB-TOKEN' => 'env-token' })
        .to_return(status: 201, body: { test_splits: [] }.to_json)

      described_class.new.request

      expect(stub).to have_been_requested
    end
  end
end
