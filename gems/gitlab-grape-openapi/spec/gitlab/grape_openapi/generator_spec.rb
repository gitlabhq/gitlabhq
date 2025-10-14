# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Generator do
  subject(:generator) { described_class.new(api_classes, options) }

  let(:api_classes) { [] }
  let(:options) { {} }

  describe '#generate' do
    it 'returns empty JSON string' do
      expect(generator.generate).to eq('{}')
    end
  end
end
