# frozen_string_literal: true

require_relative '../../caproni/scripts/seed_oidc_application'

RSpec.describe SeedOidcApplication do
  describe '.seed_program' do
    subject(:program) do
      described_class.seed_program(uid: uid, secret: secret, consumer_url: consumer_url)
    end

    let(:uid) { 'consumer-client-id' }
    # Has a quote and an interpolation marker, so raw rendering fails here
    let(:secret) { %(se"cret-\#{system("id")}) }
    let(:consumer_url) { 'http://consumer.example.com' }

    it 'renders the secret as an escaped literal rather than interpolating it raw' do
      expect(program).to include("encode(#{secret.inspect})")
      expect(program).not_to include(%(encode("#{secret}")))
    end

    it 'skips seeding when the uid already exists, so a re-run is a no-op' do
      expect(program).to include("exists?(uid: #{uid.inspect})")
    end

    it 'creates the application under the same uid it checked for' do
      expect(program.scan(uid.inspect).size).to eq(2)
    end

    it 'registers the callback of each provider on the consumer' do
      callbacks = 'http://consumer.example.com/users/auth/openid_connect/callback\n' \
        'http://consumer.example.com/users/auth/gitlab/callback'

      expect(program).to include(%(redirect_uri: "#{callbacks}"))
    end

    it 'creates a trusted, confidential application so no authorization screen is shown' do
      expect(program).to include('trusted: true').and include('confidential: true')
    end
  end
end
