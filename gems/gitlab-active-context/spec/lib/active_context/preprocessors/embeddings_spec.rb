# frozen_string_literal: true

RSpec.describe "ActiveContext::Preprocessors::Embeddings#apply_embeddings", :aggregate_failures do
  describe '.apply_embeddings' do
    it_behaves_like 'content_method and content_field variations',
      embeddings_method: :apply_embeddings,
      mock_reference_base_class: Test::References::MockWithDatabaseRecord
  end

  describe 'handling errors during embedding generation' do
    let(:mock_reference_class) do
      klass = Class.new(Test::References::MockWithDatabaseRecord) do
        add_preprocessor :embeddings do |refs|
          apply_embeddings(
            refs: refs, content_method: :embedding_content
          )
        end

        def embedding_content
          'content returned in reference method'
        end
      end

      stub_const('MockEmbeddingsReferenceClass', klass)
    end

    let(:partition) { 2 }
    let(:collection_id) { 1 }
    let(:mock_reference_record_id) { 5 }

    let(:mock_adapter) { double }
    let(:mock_collection_record) do
      double(name: 'mock_collection', partition_for: partition, include_ref_fields: true,
        collection_class: 'Test::Collections::Mock')
    end

    let(:test_reference) do
      mock_reference_class.new(collection_id: collection_id, routing: partition, args: mock_reference_record_id)
    end

    let(:mock_embedding_model) do
      ::ActiveContext::EmbeddingModel.new(
        model_ref: 'test-model-001',
        field: 'embeddings_v1',
        model_type: 'gitlab_managed',
        llm_class: Test::MockLlmClass,
        llm_params: { abc: "extra-params" }
      )
    end

    before do
      allow(ActiveContext).to receive(:adapter).and_return(mock_adapter)
      allow(ActiveContext::CollectionCache).to receive(:fetch).and_return(mock_collection_record)

      allow(test_reference).to receive(:indexing_embedding_models).and_return([mock_embedding_model])

      allow(ActiveContext::Logger).to receive(:info)
      allow(ActiveContext::Logger).to receive(:exception)
    end

    describe 'rate limit error handling' do
      let(:rate_limit_error) { Class.new(StandardError) }

      let(:mock_reference_class) do
        error_class = rate_limit_error

        Class.new(Test::References::MockWithDatabaseRecord) do
          add_preprocessor :embeddings do |refs|
            apply_embeddings(
              refs: refs, content_method: :embedding_content, infinite_retry_error_types: [error_class]
            )
          end

          def embedding_content
            'content returned in reference method'
          end
        end
      end

      before do
        allow(mock_embedding_model).to receive(:generate_embeddings).and_raise(
          rate_limit_error,
          '429 Too Many Requests'
        )
      end

      it 'marks refs as infinite_retry instead of failed, so they retry without dead-lettering' do
        result = ActiveContext::Reference.preprocess_references([test_reference])

        expect(result[:successful]).to be_empty
        expect(result[:failed]).to be_empty
        expect(result[:infinite_retry]).to eq([test_reference])
      end
    end

    describe 'retry error handling' do
      before do
        allow(mock_embedding_model).to receive(:generate_embeddings).and_raise(ArgumentError, 'Invalid argument')
      end

      it 'marks the refs as failed and logs the error' do
        expect(ActiveContext::Logger).to receive(:exception).with(
          instance_of(ArgumentError),
          handling: :retryable,
          class_name: mock_reference_class.name,
          queue_name: nil,
          preprocessor: 'embeddings',
          refs_count: 1,
          refs_sample: [test_reference.serialize]
        )

        result = ActiveContext::Reference.preprocess_references([test_reference])

        expect(result[:successful]).to be_empty
        expect(result[:failed]).to eq([test_reference])
      end

      context 'when the queue_name is specified' do
        it 'does not log the queue name if the reference class does not pass it' do
          expect(ActiveContext::Logger).to receive(:exception).with(
            instance_of(ArgumentError),
            handling: :retryable,
            class_name: mock_reference_class.name,
            queue_name: nil,
            preprocessor: 'embeddings',
            refs_count: 1,
            refs_sample: [test_reference.serialize]
          )

          ActiveContext::Reference.preprocess_references([test_reference], queue_name: 'test_queue')
        end

        context 'when the reference class passes the queue_name' do
          let(:mock_reference_class) do
            klass = Class.new(Test::References::MockWithDatabaseRecord) do
              add_preprocessor :embeddings do |refs, queue_name: nil|
                apply_embeddings(
                  refs: refs, content_method: :embedding_content, queue_name: queue_name
                )
              end

              def embedding_content
                'content returned in reference method'
              end
            end

            stub_const('MockEmbeddingsReferenceClassWithQueueName', klass)
          end

          it 'logs the queue_name' do
            expect(ActiveContext::Logger).to receive(:exception).with(
              instance_of(ArgumentError),
              handling: :retryable,
              class_name: mock_reference_class.name,
              queue_name: 'test_queue',
              preprocessor: 'embeddings',
              refs_count: 1,
              refs_sample: [test_reference.serialize]
            )

            ActiveContext::Reference.preprocess_references([test_reference], queue_name: 'test_queue')
          end
        end
      end
    end

    describe 'error_types passthrough' do
      let(:declared_error) { Class.new(StandardError) }

      let(:mock_reference_class) do
        error_class = declared_error

        Class.new(Test::References::MockWithDatabaseRecord) do
          add_preprocessor :embeddings do |refs|
            apply_embeddings(
              refs: refs, content_method: :embedding_content, error_types: [error_class]
            )
          end

          def embedding_content
            'content returned in reference method'
          end
        end
      end

      context 'when the raised error matches the caller-declared error_types' do
        before do
          allow(mock_embedding_model).to receive(:generate_embeddings).and_raise(declared_error, 'expected failure')
        end

        it 'fails the ref and logs it as a retryable exception' do
          expect(ActiveContext::Logger).to receive(:exception).with(anything, hash_including(handling: :retryable))

          result = ActiveContext::Reference.preprocess_references([test_reference])

          expect(result[:failed]).to eq([test_reference])
        end
      end

      context 'when the raised error is not in the caller-declared error_types' do
        before do
          allow(mock_embedding_model).to receive(:generate_embeddings).and_raise(NoMethodError, 'undefined method')
        end

        it 'still fails the ref through the retry chain, but logs it loudly instead' do
          expect(ActiveContext::Logger).to receive(:exception).with(anything, hash_including(handling: :unexpected))

          result = ActiveContext::Reference.preprocess_references([test_reference])

          expect(result[:failed]).to eq([test_reference])
        end
      end
    end
  end
end
