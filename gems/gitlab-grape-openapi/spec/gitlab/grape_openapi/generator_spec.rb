# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Generator do
  subject(:generator) { described_class.new(api_classes, options) }

  let(:api_classes) { [] }
  let(:options) { {} }

  describe '#generate' do
    it 'returns string with correct keys' do
      expect(generator.generate.keys).to contain_exactly(:servers, :components, :security)
    end
  end
end
