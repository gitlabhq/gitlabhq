# frozen_string_literal: true

RSpec.describe Bitbucket::Connection do
  subject(:bitbucket_connection) { described_class.new(options, http_client: class_double(HTTParty)) }

  let(:options) do
    {
      token: 'foo',
      refresh_token: 'bar',
      expires_in: 7200,
      app_id: 'app-id',
      app_secret: 'app-secret'
    }
  end

  describe '#connection' do
    context 'when oauth' do
      it 'uses OAuth connection' do
        expect(bitbucket_connection.connection).to be_an_instance_of(Bitbucket::OauthConnection)
      end

      context 'when app_id or app_secret is missing' do
        let(:options) { { token: 'foo' } }

        it 'raises KeyError' do
          expect { bitbucket_connection.connection }.to raise_error(KeyError)
        end
      end
    end

    context 'when api token' do
      let(:options) do
        {
          email: 'user@example.com',
          api_token: 'token123'
        }
      end

      it 'uses API connection' do
        expect(bitbucket_connection.connection).to be_an_instance_of(Bitbucket::ApiConnection)
      end

      it 'stores email and api_token' do
        connection = bitbucket_connection.connection

        expect(connection.email).to eq('user@example.com')
        expect(connection.api_token).to eq('token123')
      end
    end
  end

  describe '#get' do
    it 'delegates to underlying connection' do
      oauth_connection = instance_double(Bitbucket::OauthConnection)
      allow(Bitbucket::OauthConnection).to receive(:new).and_return(oauth_connection)
      expect(oauth_connection).to receive(:get).with('/path')

      bitbucket_connection.get('/path')
    end
  end

  describe '#get_response_code' do
    it 'delegates to underlying connection' do
      oauth_connection = instance_double(Bitbucket::OauthConnection)
      allow(Bitbucket::OauthConnection).to receive(:new).and_return(oauth_connection)
      expect(oauth_connection).to receive(:get_response_code).with('/path')

      bitbucket_connection.get_response_code('/path')
    end
  end

  describe '#refresh_if_expired!' do
    it 'delegates to underlying connection' do
      oauth_connection = instance_double(Bitbucket::OauthConnection)
      allow(Bitbucket::OauthConnection).to receive(:new).and_return(oauth_connection)
      expect(oauth_connection).to receive(:refresh_if_expired!)

      bitbucket_connection.refresh_if_expired!
    end
  end
end
