# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Cells::Mailroom::Forwarder do
  subject(:forwarder) do
    described_class.new(mailbox_type: 'incoming_email', signing_key_path: '/does/not/matter', logger: logger)
  end

  let(:logger) { instance_double(Logger, info: nil, warn: nil) }
  let(:connection) { instance_double(Faraday::Connection) }
  let(:response) { instance_double(Faraday::Response, status: 200, success?: true) }

  describe '#forward' do
    before do
      allow(forwarder).to receive_messages(connection: connection, jwt_token: 'signed-jwt')
    end

    it 'posts to the cell internal mail_room endpoint, treating the address as a host' do
      expect(connection).to receive(:post)
        .with('https://cell-1.example.com:443/api/v4/internal/mail_room/incoming_email', 'raw email')
        .and_return(response)

      expect(forwarder.forward('raw email', 'cell-1.example.com:443')).to be(true)
    end

    it 'uses the configured mailbox type in the path' do
      forwarder = described_class.new(mailbox_type: 'service_desk_email', signing_key_path: '/x', logger: logger)
      allow(forwarder).to receive_messages(connection: connection, jwt_token: 'signed-jwt')

      expect(connection).to receive(:post)
        .with('https://cell-1.example.com:443/api/v4/internal/mail_room/service_desk_email', 'raw')
        .and_return(response)

      forwarder.forward('raw', 'cell-1.example.com:443')
    end

    it 'uses the configured scheme' do
      forwarder = described_class.new(mailbox_type: 'incoming_email', signing_key_path: '/x', scheme: 'http',
        logger: logger)
      allow(forwarder).to receive_messages(connection: connection, jwt_token: 'signed-jwt')

      expect(connection).to receive(:post)
        .with('http://cell-1.example.com:443/api/v4/internal/mail_room/incoming_email', 'raw')
        .and_return(response)

      forwarder.forward('raw', 'cell-1.example.com:443')
    end

    it 'defaults the scheme to https' do
      expect(described_class::DEFAULT_SCHEME).to eq('https')
    end

    it 'sets the content type and JWT auth headers' do
      headers = {}
      request = instance_double(Faraday::Request, headers: headers)
      allow(connection).to receive(:post).and_yield(request).and_return(response)

      forwarder.forward('raw', 'cell-1.example.com:443')

      expect(headers['Content-Type']).to eq('text/plain')
      expect(headers[described_class::INTERNAL_API_REQUEST_HEADER]).to eq('signed-jwt')
    end

    it 'returns false and does not raise when the request fails' do
      allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed, 'down')

      expect(forwarder.forward('raw', 'cell-1.example.com:443')).to be(false)
    end
  end

  describe '#jwt_token' do
    let(:private_key) { OpenSSL::PKey::EC.generate('prime256v1') }
    let(:public_key) { OpenSSL::PKey::EC.new(private_key.public_to_pem) }
    let(:signing_key_file) { Tempfile.create('signing_key') }
    let(:signing_key_path) { signing_key_file.path }

    subject(:forwarder) do
      described_class.new(mailbox_type: 'incoming_email', signing_key_path: signing_key_path, logger: logger)
    end

    before do
      signing_key_file.write(private_key.to_pem)
      signing_key_file.close
    end

    after do
      File.unlink(signing_key_path) if File.exist?(signing_key_path)
    end

    it 'signs the payload with ES256 and the key kid so a cell can verify it' do
      token = forwarder.send(:jwt_token)

      kid = ::JWT::JWK.new(public_key).export[:kid]
      jwks = ::JWT::JWK::Set.new([::JWT::JWK.new(public_key)])
      payload, header = ::JWT.decode(token, nil, true, algorithms: ['ES256'], jwks: jwks)

      expect(header).to include('alg' => 'ES256', 'kid' => kid)
      expect(payload).to include('iss' => described_class::JWT_ISSUER, 'iat' => be_a(Integer), 'nonce' => be_a(String))
    end

    it 'sets a short-lived expiry so an intercepted token cannot be replayed indefinitely' do
      token = forwarder.send(:jwt_token)

      jwks = ::JWT::JWK::Set.new([::JWT::JWK.new(public_key)])
      payload, = ::JWT.decode(token, nil, true, algorithms: ['ES256'], jwks: jwks)

      expect(payload['exp']).to eq(payload['iat'] + described_class::JWT_EXPIRY_SECONDS)
    end

    it 'produces a token that fails verification once expired' do
      travel_to = Time.now - (described_class::JWT_EXPIRY_SECONDS + 1)
      allow(Time).to receive(:now).and_return(travel_to)
      token = forwarder.send(:jwt_token)
      allow(Time).to receive(:now).and_call_original

      jwks = ::JWT::JWK::Set.new([::JWT::JWK.new(public_key)])

      expect do
        ::JWT.decode(token, nil, true, algorithms: ['ES256'], jwks: jwks)
      end.to raise_error(::JWT::ExpiredSignature)
    end

    it 'rejects verification with a different key' do
      token = forwarder.send(:jwt_token)

      other_key = OpenSSL::PKey::EC.generate('prime256v1')
      other_public = OpenSSL::PKey::EC.new(other_key.public_to_pem)

      expect do
        ::JWT.decode(token, other_public, true, algorithms: ['ES256'])
      end.to raise_error(::JWT::VerificationError)
    end
  end

  describe 'connection timeouts' do
    subject(:forwarder) do
      described_class.new(mailbox_type: 'incoming_email', signing_key_path: '/x', logger: logger)
    end

    it 'configures open and read timeouts so a slow cell cannot block the poller' do
      connection = forwarder.send(:connection)

      expect(connection.options.open_timeout).to eq(described_class::OPEN_TIMEOUT_SECONDS)
      expect(connection.options.timeout).to eq(described_class::TIMEOUT_SECONDS)
    end
  end
end
