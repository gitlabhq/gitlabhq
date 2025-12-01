# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Opensearch::Executor do
  before do
    allow(adapter).to receive(:client).and_return(client)
  end

  let(:client) { double('Client', client: raw_client) }
  let(:raw_client) { double('RawClient') }
  let(:adapter) do
    double('Adapter', connection: connection, separator: '_', full_collection_name: ->(name) {
      "prefix_#{name}"
    })
  end

  let(:connection) { double('Connection') }

  it_behaves_like 'an elastic executor'

  subject(:executor) { described_class.new(adapter) }

  describe '#vector_field_mapping' do
    it 'returns OpenSearch-specific vector mapping' do
      field = ActiveContext::Databases::Field::Vector.new(:embedding, dimensions: 768)

      mapping = executor.vector_field_mapping(field)

      expect(mapping).to eq(
        type: 'knn_vector',
        dimension: 768,
        method: {
          name: 'hnsw',
          engine: 'lucene',
          space_type: 'cosinesimil',
          parameters: {
            ef_construction: 100,
            m: 16
          }
        }
      )
    end

    it 'uses dimensions from field options' do
      field = ActiveContext::Databases::Field::Vector.new(:embedding, dimensions: 1536)

      mapping = executor.vector_field_mapping(field)

      expect(mapping[:dimension]).to eq(1536)
    end

    it 'uses correct HNSW parameters matching Elasticsearch defaults' do
      field = ActiveContext::Databases::Field::Vector.new(:embedding, dimensions: 768)

      mapping = executor.vector_field_mapping(field)

      expect(mapping[:method][:parameters][:ef_construction]).to eq(described_class::EF_CONSTRUCTION)
      expect(mapping[:method][:parameters][:m]).to eq(described_class::M)
    end
  end

  describe '#settings' do
    let(:indices_client) { double('IndicesClient') }

    context 'when fields include vector fields' do
      it 'enables knn in settings' do
        fields = [
          ActiveContext::Databases::Field::Keyword.new(:title),
          ActiveContext::Databases::Field::Vector.new(:embedding, dimensions: 768)
        ]

        settings = executor.send(:settings, fields)

        expect(settings).to eq({ index: { knn: true } })
      end
    end

    context 'when fields do not include vector fields' do
      it 'returns empty settings' do
        fields = [
          ActiveContext::Databases::Field::Keyword.new(:title),
          ActiveContext::Databases::Field::Text.new(:description)
        ]

        settings = executor.send(:settings, fields)

        expect(settings).to eq({})
      end
    end
  end

  describe '#mappings with vector fields' do
    let(:indices_client) { double('IndicesClient') }

    it 'includes vector field mapping in mappings' do
      fields = [
        ActiveContext::Databases::Field::Keyword.new(:title),
        ActiveContext::Databases::Field::Vector.new(:embedding, dimensions: 768)
      ]

      mappings = executor.send(:mappings, fields)

      expect(mappings).to include(
        'title' => { type: 'keyword' },
        'embedding' => {
          type: 'knn_vector',
          dimension: 768,
          method: {
            name: 'hnsw',
            engine: 'lucene',
            space_type: 'cosinesimil',
            parameters: {
              ef_construction: 100,
              m: 16
            }
          }
        },
        ref_id: { type: 'keyword' },
        ref_version: { type: 'long' }
      )
    end
  end
end
