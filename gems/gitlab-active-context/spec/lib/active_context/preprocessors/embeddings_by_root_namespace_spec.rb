# frozen_string_literal: true

RSpec.describe "ActiveContext::Preprocessors::Embeddings#apply_embeddings_by_root_namespace", :aggregate_failures do
  let(:mock_reference_class) do
    klass = Class.new(Test::References::MockWithWritableRootNamespace) do
      add_preprocessor :embeddings do |refs|
        apply_embeddings_by_root_namespace(refs: refs)
      end
    end

    stub_const('MockRootNamespaceReferenceClass', klass)
  end

  let(:partition) { 2 }
  let(:collection_id) { 1 }
  let(:refs_root_namespace_id) { 357 }

  let(:ref1_record_id) { 5 }
  let(:ref1_record) { double(id: ref1_record_id) }
  let(:ref1) do
    mock_reference_class.new(
      collection_id: collection_id, routing: partition, args: ref1_record_id
    ).tap do |ref|
      ref.root_namespace_id = refs_root_namespace_id
    end
  end

  let(:ref2_record_id) { 11111 }
  let(:ref2_record) { double(id: ref2_record_id) }
  let(:ref2) { mock_reference_class.new(collection_id: collection_id, routing: partition, args: ref2_record_id) }

  let(:ref3_record_id) { 12345 }
  let(:ref3_record) { double(id: ref3_record_id) }
  let(:ref3) do
    mock_reference_class.new(
      collection_id: collection_id, routing: partition, args: ref3_record_id
    ).tap do |ref|
      ref.root_namespace_id = refs_root_namespace_id
    end
  end

  let(:mock_adapter) { double }
  let(:mock_collection_record) do
    double(name: 'mock_collection', partition_for: partition, include_ref_fields: true,
      collection_class: 'Test::Collections::Mock')
  end

  let(:test_model_key) { 'test-model-001' }
  let(:model_type) { 'gitlab_managed' }
  let(:mock_embedding_model) do
    ::ActiveContext::EmbeddingModel.new(
      model_ref: test_model_key,
      field: 'embeddings_v1',
      model_type: model_type,
      llm_class: Test::MockLlmClass,
      llm_params: { abc: "extra-params" }
    )
  end

  subject(:preprocess_references) { ActiveContext::Reference.preprocess_references([ref1, ref2, ref3]) }

  before do
    allow(ActiveContext).to receive(:adapter).and_return(mock_adapter)
    allow(ActiveContext::CollectionCache).to receive(:fetch).and_return(mock_collection_record)

    allow(mock_reference_class.model_klass).to receive(:find_by).with(id: ref1_record_id).and_return(ref1_record)
    allow(ref1).to receive(:indexing_embedding_models).and_return([mock_embedding_model])

    allow(mock_reference_class.model_klass).to receive(:find_by).with(id: ref2_record_id).and_return(ref2_record)
    allow(ref2).to receive(:indexing_embedding_models).and_return([mock_embedding_model])

    allow(mock_reference_class.model_klass).to receive(:find_by).with(id: ref3_record_id).and_return(ref3_record)
    allow(ref3).to receive(:indexing_embedding_models).and_return([mock_embedding_model])

    ref1.documents << { content: 'ref1 embedding content' }
    ref2.documents << { content: 'ref2 embedding content' }
    ref3.documents << { content: 'ref3 embedding content' }

    allow(ActiveContext::Logger).to receive(:info)
    allow(ActiveContext::Logger).to receive(:retryable_exception)
  end

  it 'generates embeddings per namespace' do
    expect(Test::MockLlmClass).to receive(:new).with(
      ['ref1 embedding content', 'ref3 embedding content'],
      user: nil,
      root_namespace_id: refs_root_namespace_id,
      abc: "extra-params"
    ).ordered.and_call_original
    expect(Test::MockLlmClass).to receive(:new).with(
      ['ref2 embedding content'],
      user: nil,
      root_namespace_id: nil,
      abc: "extra-params"
    ).ordered.and_call_original

    preprocessed_result = preprocess_references

    expect(preprocessed_result).to eq({ successful: [ref1, ref3, ref2], failed: [] })

    preprocessed_ref1 = preprocessed_result[:successful][0]
    expect(preprocessed_ref1.documents).to match_array([{
      content: 'ref1 embedding content', embeddings_v1: Test::MockLlmClass.mock_vectors
    }])

    preprocessed_ref3 = preprocessed_result[:successful][1]
    expect(preprocessed_ref3.documents).to match_array([{
      content: 'ref3 embedding content', embeddings_v1: Test::MockLlmClass.mock_vectors
    }])

    preprocessed_ref2 = preprocessed_result[:successful][2]
    expect(preprocessed_ref2.documents).to match_array([{
      content: 'ref2 embedding content', embeddings_v1: Test::MockLlmClass.mock_vectors
    }])
  end

  describe 'error handling' do
    before do
      allow(mock_embedding_model).to receive(:generate_embeddings).and_raise(ArgumentError, 'Invalid argument')
    end

    it 'sets the refs as failed and logs the error' do
      expect(ActiveContext::Logger).to receive(:retryable_exception).with(
        instance_of(ArgumentError),
        class_name: mock_reference_class.name,
        queue_name: nil,
        preprocessor: 'embeddings',
        refs_count: 2,
        refs_sample: [ref1.serialize, ref3.serialize]
      ).ordered
      expect(ActiveContext::Logger).to receive(:retryable_exception).with(
        instance_of(ArgumentError),
        class_name: mock_reference_class.name,
        queue_name: nil,
        preprocessor: 'embeddings',
        refs_count: 1,
        refs_sample: [ref2.serialize]
      ).ordered

      result = preprocess_references

      expect(result[:successful]).to be_empty
      expect(result[:failed]).to eq([ref1, ref3, ref2])
    end

    context 'when the queue_name is specified' do
      subject(:preprocess_references) do
        ActiveContext::Reference.preprocess_references([ref1, ref2, ref3], queue_name: 'test_queue')
      end

      it 'does not log the queue name if the reference class does not pass it' do
        expect(ActiveContext::Logger).to receive(:retryable_exception).with(
          instance_of(ArgumentError),
          class_name: mock_reference_class.name,
          queue_name: nil,
          preprocessor: 'embeddings',
          refs_count: 2,
          refs_sample: [ref1.serialize, ref3.serialize]
        ).ordered
        expect(ActiveContext::Logger).to receive(:retryable_exception).with(
          instance_of(ArgumentError),
          class_name: mock_reference_class.name,
          queue_name: nil,
          preprocessor: 'embeddings',
          refs_count: 1,
          refs_sample: [ref2.serialize]
        ).ordered

        preprocess_references
      end

      context 'when the reference class passes the queue_name' do
        let(:mock_reference_class) do
          klass = Class.new(Test::References::MockWithWritableRootNamespace) do
            add_preprocessor :embeddings do |refs, queue_name: nil|
              apply_embeddings_by_root_namespace(
                refs: refs, queue_name: queue_name
              )
            end
          end

          stub_const('MockRootNamespaceReferenceClassWithQueueName', klass)
        end

        it 'logs the queue_name' do
          expect(ActiveContext::Logger).to receive(:retryable_exception).with(
            instance_of(ArgumentError),
            class_name: mock_reference_class.name,
            queue_name: 'test_queue',
            preprocessor: 'embeddings',
            refs_count: 2,
            refs_sample: [ref1.serialize, ref3.serialize]
          )
          expect(ActiveContext::Logger).to receive(:retryable_exception).with(
            instance_of(ArgumentError),
            class_name: mock_reference_class.name,
            queue_name: 'test_queue',
            preprocessor: 'embeddings',
            refs_count: 1,
            refs_sample: [ref2.serialize]
          )

          preprocess_references
        end
      end
    end

    context 'when only some embeddings generation have failed' do
      before do
        allow(mock_embedding_model).to receive(:generate_embeddings).and_call_original
        allow(mock_embedding_model).to receive(:generate_embeddings).with(
          ['ref2 embedding content'], any_args).and_raise(ArgumentError, 'Invalid argument')
      end

      it 'sets the affected refs as failed while the other refs are successful' do
        expect(ActiveContext::Logger).to receive(:retryable_exception).with(
          instance_of(ArgumentError),
          class_name: mock_reference_class.name,
          queue_name: nil,
          preprocessor: 'embeddings',
          refs_count: 1,
          refs_sample: [ref2.serialize]
        )

        result = preprocess_references

        expect(result[:successful]).to eq([ref1, ref3])
        expect(result[:failed]).to eq([ref2])
      end
    end
  end

  # These contexts are already covered in the `ActiveContext::Preprocessors::Embeddings#apply_embeddings` spec
  # TODO: extract the content-variation tests in `apply_embeddings` into shared_examples
  describe '`content_method` and `content_field` variations' do
    context 'when :content_method is passed and defined' do
      pending 'embeds the correct content'
    end

    context 'when :content_method is passed but not defined' do
      pending 'embeds the correct content'
    end

    context 'when :content_method is not passed' do
      pending 'embeds the correct content'
    end
  end
end
