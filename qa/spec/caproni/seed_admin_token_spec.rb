# frozen_string_literal: true

require_relative '../../caproni/scripts/seed_admin_token'

RSpec.describe SeedAdminToken do
  describe '.seed_program' do
    subject(:program) { described_class.seed_program(token) }

    # Has a quote and an interpolation marker, so raw rendering fails here
    let(:token) { %(gl"pat-\#{system("id")}) }

    it 'renders the token as an escaped literal rather than interpolating it raw' do
      expect(program).to include("pat.set_token(#{token.inspect})")
      expect(program).not_to include(%(pat.set_token("#{token}")))
    end

    it 'skips seeding when the token already exists, so a re-run is a no-op' do
      expect(program).to include("exists?(name: #{described_class::TOKEN_NAME.inspect})")
    end

    it 'builds the token under the same name it checked for' do
      expect(program.scan(described_class::TOKEN_NAME).size).to eq(2)
    end
  end
end
