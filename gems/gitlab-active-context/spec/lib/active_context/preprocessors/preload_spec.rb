# frozen_string_literal: true

RSpec.describe ActiveContext::Preprocessors::Preload do
  let(:reference_class) do
    Class.new(Test::References::MockWithDatabaseRecord) do
      include ::ActiveContext::Preprocessors::Preload

      add_preprocessor :preload do |refs|
        preload(refs)
      end
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

  subject(:preprocess_refs) { ActiveContext::Reference.preprocess_references([reference_1, reference_2]) }

  before do
    allow(ActiveContext).to receive(:adapter).and_return(mock_adapter)
    allow(ActiveContext::CollectionCache).to receive(:fetch).and_return(mock_collection)
    allow(ActiveContext::Logger).to receive(:exception).and_return(nil)
    allow(reference_class).to receive(:model_klass).and_return(mock_relation)
  end

  context 'when the model klass implements :preload_indexing_data' do
    before do
      allow(mock_relation).to receive(:preload_indexing_data)
    end

    it 'preloads in batches' do
      expect(reference_class).to receive(:preload_batch).once

      preprocess_refs
    end

    context 'when the batch size is less than the number of references' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 1)
      end

      it 'preloads in batches' do
        expect(reference_class).to receive(:preload_batch).twice

        preprocess_refs
      end
    end
  end

  context 'when the model klass does not implement :preload_indexing_data' do
    it 'logs and does not raise an error' do
      expect(::ActiveContext::Logger).to receive(:exception).with(ActiveContext::Preprocessors::Preload::IndexingError)

      expect { preprocess_refs }.not_to raise_error
    end

    it 'returns references' do
      expect(preprocess_refs).to eq([reference_1, reference_2])
    end
  end
end
