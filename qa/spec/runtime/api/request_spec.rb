# frozen_string_literal: true

RSpec.describe QA::Runtime::API::Request do
  let(:client)  { QA::Runtime::API::Client.new('http://example.com', personal_access_token: 'a_token') }
  let(:request) { described_class.new(client, '/users') }

  describe '#url' do
    it 'returns the full API request url' do
      expect(request.url).to eq 'http://example.com/api/v4/users?private_token=a_token'
    end

    context 'when oauth_access_token is passed in the query string' do
      let(:request) { described_class.new(client, '/users', oauth_access_token: 'foo') }

      it 'does not adds a private_token query string' do
        expect(request.url).to eq 'http://example.com/api/v4/users?oauth_access_token=foo'
      end
    end
  end

  describe '#mask_url' do
    it 'returns the full API request url with the token masked' do
      expect(request.mask_url).to eq 'http://example.com/api/v4/users?private_token=[****]'
    end
  end

  describe '#request_path' do
    it 'prepends the api path' do
      expect(request.request_path('/users')).to eq '/api/v4/users'
    end

    it 'adds the personal access token' do
      expect(request.request_path('/users', private_token: 'token'))
        .to eq '/api/v4/users?private_token=token'
    end

    it 'adds the oauth access token' do
      expect(request.request_path('/users', access_token: 'otoken'))
        .to eq '/api/v4/users?access_token=otoken'
    end

    it 'respects query parameters', :aggregate_failures do
      expect(request.request_path('/users?page=1')).to eq '/api/v4/users?page=1'
      expect(request.request_path('/users', private_token: 'token', foo: 'bar/baz'))
        .to eq '/api/v4/users?private_token=token&foo=bar%2Fbaz'
      expect(request.request_path('/users?page=1', private_token: 'token', foo: 'bar/baz'))
        .to eq '/api/v4/users?page=1&private_token=token&foo=bar%2Fbaz'
      expect(request.request_path('/users', per_page: 100)).to eq '/api/v4/users?per_page=100'
    end

    it 'uses a different api version' do
      expect(request.request_path('/users', version: 'other_version')).to eq '/api/other_version/users'
    end
  end
end
