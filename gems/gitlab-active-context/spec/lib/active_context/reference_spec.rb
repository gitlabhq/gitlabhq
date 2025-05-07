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

      it 'returns nil' do
        expect(described_class.deserialize('test|string')).to be_nil
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

  describe '#jsons' do
    let(:reference_class) { Class.new(Test::References::Mock) }
    let(:reference) { reference_class.new(collection_id: 1, routing: 2, args: 3) }
    let(:mock_collection) { double(include_ref_fields: include_ref_fields) }
    let(:include_ref_fields) { false }

    before do
      allow(ActiveContext::CollectionCache).to receive(:fetch).and_return(mock_collection)
      allow(reference).to receive(:identifier).and_return('test-id')
      allow(reference).to receive(:unique_identifier).with(0).and_return('test-id:0')
      allow(reference).to receive(:unique_identifier).with(1).and_return('test-id:1')
      reference.instance_variable_set(:@ref_version, 12345)
    end

    context 'when documents are already set' do
      before do
        reference.documents = [{ field1: 'value1' }, { field1: 'value2' }]
      end

      it 'uses the existing documents' do
        expect(reference).not_to receive(:as_indexed_jsons)

        result = reference.jsons
        expect(result).to contain_exactly(
          { field1: 'value1', unique_identifier: 'test-id:0' },
          { field1: 'value2', unique_identifier: 'test-id:1' }
        )
      end
    end

    context 'when documents are not set' do
      before do
        allow(reference).to receive(:as_indexed_jsons).and_return([
          { field1: 'value1' },
          { field1: 'value2' }
        ])
      end

      it 'calls as_indexed_jsons to get documents' do
        expect(reference).to receive(:as_indexed_jsons)

        result = reference.jsons
        expect(result).to contain_exactly(
          { field1: 'value1', unique_identifier: 'test-id:0' },
          { field1: 'value2', unique_identifier: 'test-id:1' }
        )
      end
    end

    context 'when the class responds to shared_attributes' do
      before do
        reference.documents = [{ field1: 'value1' }, { field1: 'value2' }]
        allow(reference).to receive(:shared_attributes).and_return({ shared_field: 'shared_value' })
      end

      it 'merges shared attributes with each document' do
        result = reference.jsons
        expect(result).to contain_exactly(
          { field1: 'value1', shared_field: 'shared_value', unique_identifier: 'test-id:0' },
          { field1: 'value2', shared_field: 'shared_value', unique_identifier: 'test-id:1' }
        )
      end
    end

    context 'when include_ref_fields is true' do
      let(:include_ref_fields) { true }

      before do
        reference.documents = [{ field1: 'value1' }]
      end

      it 'adds ref_id and ref_version to each document' do
        result = reference.jsons
        expect(result).to contain_exactly(
          {
            field1: 'value1',
            unique_identifier: 'test-id:0',
            ref_id: 'test-id',
            ref_version: 12345
          }
        )
      end
    end
  end

  describe '#embedding_versions' do
    let(:reference_class) { Class.new(Test::References::Mock) }
    let(:reference) { reference_class.new(collection_id: 1, routing: 2, args: 3) }
    let(:mock_collection) { double(include_ref_fields: true) }
    let(:collection_class) { double }
    let(:current_embedding_versions) { [1, 2] }

    before do
      allow(ActiveContext::CollectionCache).to receive(:fetch).and_return(mock_collection)
      allow(reference).to receive(:collection_class).and_return(collection_class)
      allow(collection_class).to receive(:current_indexing_embedding_versions).and_return(current_embedding_versions)
    end

    it 'returns collection_class.current_embedding_versions' do
      expect(reference.embedding_versions).to eq(current_embedding_versions)
    end

    context 'if collection_class does not have current_embedding_versions' do
      let(:current_embedding_versions) { nil }

      it 'returns empty array' do
        expect(reference.embedding_versions).to be_empty
      end
    end

    context 'if collection_class does not exist' do
      before do
        allow(reference).to receive(:collection_class).and_return(nil)
      end

      it 'returns empty array' do
        expect(reference.embedding_versions).to be_empty
      end
    end
  end
end
