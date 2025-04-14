# frozen_string_literal: true

RSpec.describe ActiveContext::Preprocessors::Chunking do
  let(:reference_class) do
    Class.new(Test::References::Mock) do
      include ::ActiveContext::Preprocessors::Chunking

      add_preprocessor :chunk do |refs|
        chunk(refs: refs, chunker: chunker, chunk_on: :foo, field: :some_content_field)
      end

      def foo
        'Some content'
      end
    end
  end

  let(:content_1) { "Test content for reference 1" }
  let(:content_2) { "Test content for reference 2" }
  let(:reference_1) { reference_class.new(collection_id: 1, routing: 1, args: 1) }
  let(:reference_2) { reference_class.new(collection_id: 1, routing: 1, args: 1) }
  let(:references) { [reference_1, reference_2] }

  let(:mock_collection) { double(name: collection_name, partition_for: partition) }
  let(:mock_chunker) { double }

  let(:partition) { 2 }
  let(:collection_id) { 1 }
  let(:object_id) { 5 }
  let(:collection_name) { 'mock_collection' }

  let(:chunks_1) { ['Chunk 1.1', 'Chunk 1.2'] }
  let(:chunks_2) { ['Chunk 2.1'] }

  subject(:preprocess_refs) { ActiveContext::Reference.preprocess_references(references) }

  before do
    allow(reference_class).to receive(:chunker).and_return(mock_chunker)
    allow(mock_chunker).to receive(:content=)
    allow(mock_chunker).to receive(:instance_variable_set)
    allow(mock_chunker).to receive(:chunks).and_return(chunks_1, chunks_2)
    allow(ActiveContext::CollectionCache).to receive(:fetch).and_return(mock_collection)
  end

  it 'returns the references with documents populated' do
    expect(reference_1).to receive(:foo).once
    expect(reference_2).to receive(:foo).once

    result = preprocess_refs

    expect(result).to eq(references)
    expect(result[0].documents).to eq([{ some_content_field: 'Chunk 1.1' }, { some_content_field: 'Chunk 1.2' }])
    expect(result[1].documents).to eq([{ some_content_field: 'Chunk 2.1' }])
  end

  context 'when the chunker raises an error' do
    let(:error) { StandardError.new('Chunking error') }

    before do
      allow(mock_chunker).to receive(:chunks).and_raise(error)
      allow(ActiveContext::ErrorHandler).to receive(:log_and_raise_error)
    end

    it 'delegates error handling to ErrorHandler' do
      expect(ActiveContext::ErrorHandler).to receive(:log_and_raise_error).with(error)

      preprocess_refs
    end
  end
end
