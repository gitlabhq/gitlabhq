# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Elasticsearch::Executor do
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
    it 'returns Elasticsearch-specific vector mapping' do
      field = ActiveContext::Databases::Field::Vector.new(:embedding, dimensions: 768)

      mapping = executor.vector_field_mapping(field)

      expect(mapping).to eq(
        type: 'dense_vector',
        dims: 768,
        index: true,
        similarity: 'cosine'
      )
    end

    it 'uses dimensions from field options' do
      field = ActiveContext::Databases::Field::Vector.new(:embedding, dimensions: 1536)

      mapping = executor.vector_field_mapping(field)

      expect(mapping[:dims]).to eq(1536)
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
          type: 'dense_vector',
          dims: 768,
          index: true,
          similarity: 'cosine'
        },
        ref_id: { type: 'keyword' },
        ref_version: { type: 'long' }
      )
    end
  end
end
