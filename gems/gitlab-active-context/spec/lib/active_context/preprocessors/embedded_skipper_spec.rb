# frozen_string_literal: true

RSpec.describe ActiveContext::Preprocessors::EmbeddedSkipper, :aggregate_failures do
  let(:reference_class) do
    embedding_collection = collection_class

    klass = Class.new(Test::References::Mock) do
      add_preprocessor :skip_embedded do |refs, queue_name: nil, next_model_only: false, current_model_only: false, **|
        skip_embedded(
          refs: refs,
          collection: embedding_collection,
          queue_name: queue_name,
          next_model_only: next_model_only,
          current_model_only: current_model_only
        )
      end
    end

    stub_const('MockEmbeddedSkipperReferenceClass', klass)
  end

  let(:reference_1) { reference_class.new(collection_id: collection_id, routing: partition, args: 'id1') }
  let(:reference_2) { reference_class.new(collection_id: collection_id, routing: partition, args: 'id2') }

  let(:current_model) { { model_ref: 'model_1', field: 'embeddings_v1' } }
  let(:next_model) { { model_ref: 'model_2', field: 'embeddings_v2' } }
  let(:collection_record) do
    double(current_indexing_embedding_model: current_model, next_indexing_embedding_model: next_model)
  end

  let(:collection_class) { double(collection_record: collection_record) }
  let(:mock_collection) { double(name: 'mock_collection', partition_for: partition, include_ref_fields: true) }

  let(:partition) { 2 }
  let(:collection_id) { 1 }
  let(:search_results) { [] }
  let(:queries) { [] }

  before do
    allow(ActiveContext::CollectionCache).to receive(:fetch).and_return(mock_collection)
    allow(ActiveContext::Logger).to receive(:info)
    allow(ActiveContext::Logger).to receive(:exception)

    allow(collection_class).to receive(:search) do |query:, **|
      queries << query
      search_results
    end
  end

  describe '.skip_embedded' do
    context 'when some refs already have embeddings' do
      let(:search_results) { [{ 'id' => 'id1' }] }

      it 'drops the embedded refs and keeps the others' do
        result = ActiveContext::Reference.preprocess_references([reference_1, reference_2])

        expect(result[:successful]).to eq([reference_2])
        expect(result[:failed]).to be_empty
      end

      it 'searches the collection for the ids only, without a user' do
        ActiveContext::Reference.preprocess_references([reference_1, reference_2])

        expect(collection_class).to have_received(:search).once.with(
          user: nil, query: anything, source_fields: ['id']
        )
      end

      it 'logs the number of skipped refs' do
        ActiveContext::Reference.preprocess_references([reference_1, reference_2], queue_name: 'test_queue')

        expect(ActiveContext::Logger).to have_received(:info).with(
          message: 'skip_embedded',
          class_name: reference_class.name,
          queue_name: 'test_queue',
          refs_count: 2,
          skipped_count: 1
        )
      end
    end

    context 'when no ref has an embedding' do
      it 'keeps every ref' do
        result = ActiveContext::Reference.preprocess_references([reference_1, reference_2])

        expect(result[:successful]).to eq([reference_1, reference_2])
        expect(result[:failed]).to be_empty
      end
    end

    context 'with the next_model_only option' do
      it 'checks only the next embedding field' do
        ActiveContext::Reference.preprocess_references([reference_1, reference_2], next_model_only: true)

        expect(queries.map(&:inspect_ast)).to eq(
          [
            [
              'limit(2)',
              '  and',
              '    filter(id: ["id1", "id2"])',
              '    exists(embeddings_v2)'
            ].join("\n")
          ]
        )
      end
    end

    context 'without a model option' do
      it 'checks both embedding fields' do
        ActiveContext::Reference.preprocess_references([reference_1, reference_2])

        expect(queries.map(&:inspect_ast)).to eq(
          [
            [
              'limit(2)',
              '  and',
              '    filter(id: ["id1", "id2"])',
              '    exists(embeddings_v1)',
              '    exists(embeddings_v2)'
            ].join("\n")
          ]
        )
      end
    end

    context 'with the current_model_only option' do
      it 'checks only the current embedding field' do
        ActiveContext::Reference.preprocess_references([reference_1, reference_2], current_model_only: true)

        expect(queries.map(&:inspect_ast)).to eq(
          [
            [
              'limit(2)',
              '  and',
              '    filter(id: ["id1", "id2"])',
              '    exists(embeddings_v1)'
            ].join("\n")
          ]
        )
      end
    end

    context 'when the collection has no record' do
      let(:collection_record) { nil }

      it 'keeps every ref without searching' do
        result = ActiveContext::Reference.preprocess_references([reference_1, reference_2])

        expect(collection_class).not_to have_received(:search)
        expect(ActiveContext::Logger).not_to have_received(:exception)
        expect(ActiveContext::Logger).not_to have_received(:info)
        expect(result[:successful]).to eq([reference_1, reference_2])
        expect(result[:failed]).to be_empty
      end
    end

    context 'when the collection has no embedding models' do
      let(:current_model) { nil }
      let(:next_model) { nil }

      it 'keeps every ref without searching' do
        result = ActiveContext::Reference.preprocess_references([reference_1, reference_2])

        expect(collection_class).not_to have_received(:search)
        expect(ActiveContext::Logger).not_to have_received(:exception)
        expect(ActiveContext::Logger).not_to have_received(:info)
        expect(result[:successful]).to eq([reference_1, reference_2])
        expect(result[:failed]).to be_empty
      end
    end

    context 'when only the requested model is missing' do
      let(:next_model) { nil }

      it 'keeps every ref without searching' do
        result = ActiveContext::Reference.preprocess_references([reference_1, reference_2], next_model_only: true)

        expect(collection_class).not_to have_received(:search)
        expect(ActiveContext::Logger).not_to have_received(:exception)
        expect(ActiveContext::Logger).not_to have_received(:info)
        expect(result[:successful]).to eq([reference_1, reference_2])
        expect(result[:failed]).to be_empty
      end
    end

    context 'when the search raises an error' do
      before do
        allow(collection_class).to receive(:search).and_raise(StandardError, 'boom')
      end

      it 'keeps every ref and does not fail any' do
        result = ActiveContext::Reference.preprocess_references([reference_1, reference_2])

        expect(result[:successful]).to eq([reference_1, reference_2])
        expect(result[:failed]).to be_empty
      end

      it 'logs the exception as skipped' do
        ActiveContext::Reference.preprocess_references([reference_1, reference_2], queue_name: 'test_queue')

        expect(ActiveContext::Logger).to have_received(:exception).with(
          an_instance_of(StandardError),
          handling: :skipped,
          class_name: reference_class.name,
          queue_name: 'test_queue',
          preprocessor: 'skip_embedded',
          refs_count: 2
        )
      end
    end
  end
end
