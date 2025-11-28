# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::TagRegistry do
  let(:tag) { Gitlab::GrapeOpenapi::Models::Tag.new('audit_events') }
  let(:tag_registry) { described_class.new }

  describe '#register' do
    it 'adds a new tag to the registry' do
      expect { tag_registry.register(tag) }.to change { tag_registry.tags.size }.by(1)
      expect(tag_registry.tags.first[:name]).to eq('Audit Events')
    end

    it 'does not add duplicate tags' do
      tag_registry.register(tag)

      expect { tag_registry.register(tag) }.not_to change { tag_registry.tags.size }
    end
  end

  describe '#to_h' do
    subject(:hash) { tag_registry.to_h }

    context 'when tags exist' do
      before do
        tag_registry.register(tag)
        tag_registry.register(Gitlab::GrapeOpenapi::Models::Tag.new('another_tags'))
      end

      it 'returns a hash with all tags' do
        expect(hash[:tags])
          .to eq(
            [
              {
                description: "Operations concerning Audit Events", name: "Audit Events"
              },
              {
                description: "Operations concerning Another Tags", name: "Another Tags"
              }
            ]
          )
      end
    end
  end
end
