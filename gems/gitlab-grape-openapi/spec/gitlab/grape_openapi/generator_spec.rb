# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Generator do
  subject(:generator) { described_class.new(api_classes, options) }

  let(:api_classes) { [API::TestAuditEvents] }
  let(:options) { {} }

  describe '#generate' do
    it 'returns string with correct keys' do
      expect(generator.generate.keys).to contain_exactly(:servers, :components, :security, :tags)
    end

    it 'executes generate_tags' do
      generator.generate

      expect(generator.tag_registry.tags.size).to eq(5)
    end
  end
end
