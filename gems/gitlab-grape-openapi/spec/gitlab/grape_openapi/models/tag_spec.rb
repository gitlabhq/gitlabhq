# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Models::Tag do
  let(:tag) { described_class.new('TestTag') }

  describe '#initialize' do
    it 'sets the name' do
      expect(tag.name).to eq('TestTag')
    end
  end

  describe '#to_h' do
    subject(:hash) { tag.to_h }

    context 'when description is present' do
      before do
        allow(tag).to receive(:description).and_return('A test tag description')
      end

      it 'returns a hash with name and description' do
        expect(hash).to eq({ name: 'TestTag', description: 'A test tag description' })
      end
    end

    context 'when description is nil' do
      before do
        allow(tag).to receive(:description).and_return(nil)
      end

      it 'returns a hash with only name' do
        expect(hash).to eq({ name: 'TestTag' })
      end
    end
  end

  describe '#description' do
    subject(:description) { tag.description }

    it 'returns a humanized description based on the tag name' do
      expect(description).to eq('Operations concerning Testtag')
    end
  end
end
