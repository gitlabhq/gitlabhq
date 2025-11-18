# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Converters::TagConverter do
  let(:tag_registry) { Gitlab::GrapeOpenapi::TagRegistry.new }
  let(:converter) { described_class.new(API::TestAuditEvents, tag_registry) }

  describe '#convert' do
    it 'returns the number of unique tags defined' do
      converter.convert

      expect(converter.tag_registry.tags.size).to eq(5)
    end
  end
end
