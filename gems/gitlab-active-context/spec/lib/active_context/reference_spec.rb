# frozen_string_literal: true

RSpec.describe ActiveContext::Reference do
  describe '.deserialize' do
    context 'when ref_klass exists' do
      let(:mock_ref_klass) { class_double("ActiveContext::References::TestReference") }
      let(:mock_instance) { instance_double("ActiveContext::References::TestReference") }

      before do
        allow(described_class).to receive(:ref_klass).and_return(mock_ref_klass)
        allow(mock_ref_klass).to receive(:new).and_return(mock_instance)
      end

      it 'instantiates the ref_klass with the string' do
        expect(mock_ref_klass).to receive(:instantiate).with('test|string')
        described_class.deserialize('test|string')
      end
    end

    context 'when ref_klass does not exist' do
      before do
        allow(described_class).to receive(:ref_klass).and_return(nil)
        stub_const('Search::Elastic::Reference', Class.new)
      end

      it 'falls back to Search::Elastic::Reference.deserialize' do
        expect(Search::Elastic::Reference).to receive(:deserialize).with('test|string')
        described_class.deserialize('test|string')
      end
    end
  end

  describe '.ref_klass' do
    before do
      stub_const('ActiveContext::References::TestReference', Class.new(described_class))
    end

    it 'returns the correct class when it exists' do
      expect(described_class.ref_klass('ActiveContext::References::TestReference|some|data'))
        .to eq(ActiveContext::References::TestReference)
    end

    it 'returns nil when the class does not exist' do
      expect(described_class.ref_klass('ActiveContext::References::NonExistantReference|some|data')).to be_nil
    end
  end

  describe '#klass' do
    it 'returns the demodulized class name' do
      expect(described_class.new.klass).to eq('Reference')
    end
  end

  describe 'ReferenceUtils methods' do
    describe '.delimit' do
      it 'splits the string by the delimiter' do
        expect(described_class.delimit('a|b|c')).to eq(%w[a b c])
      end
    end

    describe '.join_delimited' do
      it 'joins the array with the delimiter' do
        expect(described_class.join_delimited(%w[a b c])).to eq('ActiveContext::Reference|a|b|c')
      end
    end

    describe '.ref_module' do
      it 'returns the pluralized class name' do
        expect(described_class.ref_module).to eq('ActiveContext::References')
      end
    end
  end
end
