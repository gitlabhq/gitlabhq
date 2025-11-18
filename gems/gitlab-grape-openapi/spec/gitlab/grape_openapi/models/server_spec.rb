# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Models::Server do
  subject(:server) { described_class.new(url: 'https://gitlab.com/api/v4', description: 'GitLab SaaS API') }

  describe '#to_h' do
    it 'returns a hash representation of the server' do
      expect(server.to_h).to eq({ url: 'https://gitlab.com/api/v4', description: 'GitLab SaaS API' })
    end

    context 'when description is nil' do
      subject(:server) { described_class.new(url: 'https://gitlab.com/api/v4', description: nil) }

      it 'does not include description in the hash' do
        expect(server.to_h).to eq({ url: 'https://gitlab.com/api/v4' })
      end
    end
  end
end
