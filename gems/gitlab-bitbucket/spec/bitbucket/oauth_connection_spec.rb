# frozen_string_literal: true

RSpec.describe Bitbucket::OauthConnection do
  let(:token) { 'token' }
  let(:logger) { instance_double(Logger, info: nil) }
  let(:oauth_options) do
    OmniAuth::Strategies::Bitbucket.default_options[:client_options].to_h.deep_symbolize_keys
  end

  # Build a connection with injected OAuth credentials so provider config isn't needed.
  def build_connection(extra_options = {})
    described_class.new(
      { token: token, oauth_options: oauth_options, logger: logger }.merge(extra_options),
      app_id: '', app_secret: ''
    )
  end

  describe 'credential validation' do
    it 'requires app_id and app_secret as keyword arguments' do
      expect { described_class.new({ token: token }) }
        .to raise_error(ArgumentError, /missing keyword/)
    end
  end

  describe '#get' do
    it 'calls OAuth2::AccessToken::get' do
      expected_client_options = {
        site: OmniAuth::Strategies::Bitbucket.default_options[:client_options]['site'],
        authorize_url: OmniAuth::Strategies::Bitbucket.default_options[:client_options]['authorize_url'],
        token_url: OmniAuth::Strategies::Bitbucket.default_options[:client_options]['token_url']
      }

      expect(described_class).to receive(:new).and_wrap_original do |original, *args, **kwargs|
        original.call(*args, **kwargs).tap do |instance|
          expect(instance).to receive(:retry_with_exponential_backoff).and_call_original
        end
      end

      expect(OAuth2::Client)
        .to receive(:new)
        .with(anything, anything, expected_client_options)

      expect(OAuth2::AccessToken).to receive(:new).and_wrap_original do |original, *args, **kwargs|
        original.call(*args, **kwargs).tap do |instance|
          expect(instance).to receive(:get).and_return(instance_double(OAuth2::Response, parsed: true))
        end
      end

      build_connection.get('/users')
    end

    context 'when no logger is injected (null logger fallback)' do
      it 'does not raise when a retry fires' do
        oauth2_error = OAuth2::Error.new(
          OAuth2::Response.new(
            instance_double(Faraday::Response, status: 429, headers: {}, body: 'rate limited').tap do |r|
              allow(r).to receive(:on_complete)
            end
          )
        )

        allow(OAuth2::AccessToken).to receive(:new).and_wrap_original do |original, *args, **kwargs|
          original.call(*args, **kwargs).tap do |instance|
            allow(instance).to receive(:get).and_raise(oauth2_error)
          end
        end

        stub_const('Bitbucket::ExponentialBackoff::INITIAL_DELAY', 0.0)
        allow(Random).to receive(:rand).and_return(0.001)

        # Build without logger: key - falls back to null logger
        connection = described_class.new(
          { token: token, oauth_options: oauth_options },
          app_id: '', app_secret: ''
        )

        expect { connection.get('/users') }.to raise_error(Bitbucket::ExponentialBackoff::RateLimitError)
      end
    end

    context 'when the API returns a retryable error' do
      let(:oauth2_error) do
        faraday_response = instance_double(Faraday::Response, status: 429, headers: {}, body: 'some error')
        allow(faraday_response).to receive(:on_complete)

        OAuth2::Error.new(OAuth2::Response.new(faraday_response))
      end

      before do
        allow(OAuth2::AccessToken).to receive(:new).and_wrap_original do |original, *args, **kwargs|
          original.call(*args, **kwargs).tap do |instance|
            allow(instance).to receive(:get).and_raise(oauth2_error)
          end
        end

        stub_const('Bitbucket::ExponentialBackoff::INITIAL_DELAY', 0.0)
        allow(Random).to receive(:rand).and_return(0.001)
      end

      it 'logs the retries and raises an error if it does not succeed on retry' do
        expect(logger).to receive(:info)
          .with(message: /Retrying in .+ seconds due to/)
          .twice

        expect { build_connection.get('/users') }.to raise_error(Bitbucket::ExponentialBackoff::RateLimitError)
      end
    end

    context 'when token refresh raises a transient error' do
      let(:oauth2_error) do
        faraday_response = instance_double(Faraday::Response, status: 500, headers: {}, body: 'Internal Server Error')
        allow(faraday_response).to receive(:on_complete)

        OAuth2::Error.new(OAuth2::Response.new(faraday_response))
      end

      before do
        stub_const('Bitbucket::ExponentialBackoff::INITIAL_DELAY', 0.0)
        allow(Random).to receive(:rand).and_return(0.001)
      end

      it 'retries the refresh and succeeds if the next attempt works' do
        call_count = 0
        refresh_response = instance_double(
          OAuth2::AccessToken, token: 'new_token', expires_at: nil, expires_in: nil, refresh_token: nil
        )

        allow(OAuth2::AccessToken).to receive(:new).and_wrap_original do |original, *args, **kwargs|
          original.call(*args, **kwargs).tap do |instance|
            allow(instance).to receive_messages(
              expired?: true, get: instance_double(OAuth2::Response, parsed: { 'user' => 'test' })
            )
            allow(instance).to receive(:refresh!) do
              call_count += 1
              raise oauth2_error if call_count == 1

              refresh_response
            end
          end
        end

        connection = build_connection(expires_at: 1.hour.ago.to_i)

        expect(connection.get('/users')).to eq({ 'user' => 'test' })
      end
    end
  end

  describe '#get_response_code' do
    context 'when the request succeeds' do
      it 'returns the HTTP status code as an integer' do
        oauth_response = instance_double(OAuth2::Response, status: 200, parsed: {})

        allow(OAuth2::AccessToken).to receive(:new).and_wrap_original do |original, *args, **kwargs|
          original.call(*args, **kwargs).tap do |instance|
            allow(instance).to receive_messages(get: oauth_response, expired?: false)
          end
        end

        expect(build_connection.get_response_code('/repositories/workspace/repo/issues')).to eq(200)
      end
    end

    context 'when the request returns a non-retryable error status' do
      it 'returns the HTTP status code from the error' do
        faraday_response = instance_double(Faraday::Response, status: 404, headers: {}, body: 'Not Found')
        allow(faraday_response).to receive(:on_complete)
        oauth2_error = OAuth2::Error.new(OAuth2::Response.new(faraday_response))

        allow(OAuth2::AccessToken).to receive(:new).and_wrap_original do |original, *args, **kwargs|
          original.call(*args, **kwargs).tap do |instance|
            allow(instance).to receive(:get).and_raise(oauth2_error)
          end
        end

        expect(build_connection.get_response_code('/repositories/workspace/repo/issues')).to eq(404)
      end
    end

    context 'when retries are exhausted due to rate limiting' do
      it 'raises RateLimitError' do
        allow(OAuth2::AccessToken).to receive(:new).and_wrap_original do |original, *args, **kwargs|
          original.call(*args, **kwargs).tap do |instance|
            allow(instance).to receive(:get).and_raise(Bitbucket::ExponentialBackoff::RateLimitError)
          end
        end

        expect { build_connection.get_response_code('/repositories/workspace/repo/issues') }
          .to raise_error(Bitbucket::ExponentialBackoff::RateLimitError)
      end
    end
  end

  describe '#expired?' do
    it 'calls connection.expired?' do
      expect(OAuth2::AccessToken).to receive(:new).and_wrap_original do |original, *args, **kwargs|
        original.call(*args, **kwargs).tap do |instance|
          expect(instance).to receive(:expired?).and_return(true)
        end
      end

      expect(build_connection.expired?).to be_truthy
    end
  end

  describe '#refresh!' do
    it 'calls connection.refresh!' do
      response = instance_double(
        OAuth2::AccessToken, token: token, expires_at: nil, expires_in: nil, refresh_token: nil
      )

      expect(OAuth2::AccessToken).to receive(:new).and_wrap_original do |original, *args, **kwargs|
        original.call(*args, **kwargs).tap do |instance|
          expect(instance).to receive(:refresh!).and_return(response)
        end
      end

      build_connection.refresh!
    end

    context 'when a refresh_strategy is provided' do
      let(:refresh_strategy) { double('refresh_strategy') } # -- avoid monolith dep

      it 'delegates refresh! to the strategy and does not call the API itself' do
        connection = described_class.new(
          { token: token, oauth_options: oauth_options },
          app_id: '', app_secret: '',
          refresh_strategy: refresh_strategy
        )

        expect(refresh_strategy).to receive(:refresh).with(connection)
        expect(connection).not_to receive(:perform_refresh!)

        connection.refresh!
      end
    end
  end

  describe '#refresh_if_expired!' do
    context 'when the token has expired' do
      it 'refreshes the token' do
        connection = described_class.new({ token: token }, app_id: '', app_secret: '')

        allow(connection).to receive(:expired?).and_return(true)
        expect(connection).to receive(:refresh!)

        connection.refresh_if_expired!
      end
    end

    context 'when the token has not expired' do
      it 'does not refresh the token' do
        connection = described_class.new({ token: token }, app_id: '', app_secret: '')

        allow(connection).to receive(:expired?).and_return(false)
        expect(connection).not_to receive(:refresh!)

        connection.refresh_if_expired!
      end
    end
  end

  describe '#perform_refresh!' do
    it 'rotates the in-memory credentials from the OAuth2 response', :aggregate_failures do
      response = instance_double(
        OAuth2::AccessToken,
        token: 'new-token',
        expires_at: 1.hour.from_now.to_i,
        expires_in: 3600,
        refresh_token: 'new-refresh-token'
      )

      expect(OAuth2::AccessToken).to receive(:new).and_wrap_original do |original, *args, **kwargs|
        original.call(*args, **kwargs).tap do |instance|
          expect(instance).to receive(:refresh!).and_return(response)
        end
      end

      connection = build_connection
      connection.perform_refresh!

      expect(connection.token).to eq('new-token')
      expect(connection.refresh_token).to eq('new-refresh-token')
      expect(connection.expires_at).to eq(response.expires_at)
    end
  end

  describe '#adopt_credentials' do
    it 'overwrites the in-memory credentials and clears the cached OAuth2 token', :aggregate_failures do
      connection = described_class.new(
        { token: 'old', refresh_token: 'old-refresh', oauth_options: oauth_options },
        app_id: '', app_secret: ''
      )
      previous_oauth_token = connection.send(:connection)

      connection.adopt_credentials(
        token: 'token-rotated',
        expires_at: 1.hour.from_now.to_i,
        expires_in: 3600,
        refresh_token: 'refresh-rotated'
      )

      expect(connection.token).to eq('token-rotated')
      expect(connection.refresh_token).to eq('refresh-rotated')
      expect(connection.send(:connection)).not_to equal(previous_oauth_token)
    end
  end
end
