# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Configuration do
  subject(:configuration) { described_class.new }

  describe '#api_version' do
    it 'has default value' do
      expect(configuration.api_version).to eq('v4')
    end
  end

  describe '#api_version=' do
    it 'sets api_version' do
      configuration.api_version = 'v5'

      expect(configuration.api_version).to eq('v5')
    end
  end
end
