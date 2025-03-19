# frozen_string_literal: true

RSpec.describe ActiveContext::Preprocessors::Embeddings do
  let(:reference_class) do
    Class.new(Test::References::MockWithDatabaseRecord) do
      include ::ActiveContext::Preprocessors::Embeddings

      add_preprocessor :bulk_embeddings do |refs|
        bulk_embeddings(refs)
      end

      attr_accessor :embedding
    end
  end

  let(:reference_1) { reference_class.new(collection_id: collection_id, routing: partition, args: object_id) }
  let(:reference_2) { reference_class.new(collection_id: collection_id, routing: partition, args: object_id) }

  let(:mock_adapter) { double }
  let(:mock_collection) { double(name: collection_name, partition_for: partition) }
  let(:mock_object) { double(id: object_id) }
  let(:mock_relation) { double(find_by: mock_object) }
  let(:mock_connection) { double(id: connection_id) }

  let(:connection_id) { 3 }
  let(:partition) { 2 }
  let(:collection_id) { 1 }
  let(:object_id) { 5 }
  let(:collection_name) { 'mock_collection' }
  let(:embeddings) { [[1, 2], [3, 4]] }
  let(:embedding_content) { 'some text' }

  subject(:preprocess_refs) { ActiveContext::Reference.preprocess_references([reference_1, reference_2]) }

  before do
    allow(ActiveContext).to receive(:adapter).and_return(mock_adapter)
    allow(ActiveContext::CollectionCache).to receive(:fetch).and_return(mock_collection)
    allow(ActiveContext::Logger).to receive(:exception).and_return(nil)
    allow(reference_class).to receive(:model_klass).and_return(mock_relation)
  end

  context 'when the reference klass implements :embedding_content' do
    before do
      allow(reference_class).to receive(:embedding_content).and_return(embedding_content)
    end

    it 'generates embeddings in bulk and sets the embeddings for each reference' do
      expect(ActiveContext::Embeddings).to receive(:generate_embeddings)
        .with([embedding_content, embedding_content])
        .and_return(embeddings)

      preprocess_refs

      expect(reference_1.embedding).to eq(embeddings.first)
      expect(reference_2.embedding).to eq(embeddings.last)
    end

    context 'when generating for a single reference' do
      it 'generates embeddings in bulk and sets the embeddings for the reference' do
        expect(ActiveContext::Embeddings).to receive(:generate_embeddings)
          .with([embedding_content])
          .and_return([embeddings.first])

        ActiveContext::Reference.preprocess_references([reference_1])

        expect(reference_1.embedding).to eq(embeddings.first)
      end
    end

    context 'when generate_embeddings returns an error' do
      let(:error) { StandardError }

      before do
        allow(ActiveContext::Embeddings).to receive(:generate_embeddings).and_raise(error)
      end

      it 'logs and returns all references without embeddings' do
        expect(::ActiveContext::Logger).to receive(:exception).with(error)

        expect(preprocess_refs).to eq([reference_1, reference_2])

        expect(reference_1.embedding).to be_nil
        expect(reference_2.embedding).to be_nil
      end
    end
  end

  context 'when the reference does not implement :embedding_content' do
    it 'logs and does not raise an error' do
      expect(ActiveContext::Embeddings).not_to receive(:generate_embeddings)
      expect(::ActiveContext::Logger).to receive(:exception)
        .with(ActiveContext::Preprocessors::Embeddings::IndexingError)

      expect { preprocess_refs }.not_to raise_error
    end

    it 'returns references without embeddings' do
      expect(preprocess_refs).to eq([reference_1, reference_2])

      expect(reference_1.embedding).to be_nil
      expect(reference_2.embedding).to be_nil
    end
  end
end
