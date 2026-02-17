# frozen_string_literal: true

RSpec.describe ActiveContext::Preprocessors::EmbeddingsWithModelRedesign do
  let(:mock_reference_class) do
    Class.new(Test::References::MockWithDatabaseRecord) do
      include ::ActiveContext::Preprocessors::Embeddings

      add_preprocessor :embeddings do |refs|
        apply_embeddings_with_model_redesign(
          refs: refs, content_method: :embedding_content, unit_primitive: 'test_unit_primitive'
        )
      end

      def embedding_content
        'content returned in reference method'
      end
    end
  end

  let(:partition) { 2 }
  let(:collection_id) { 1 }
  let(:mock_reference_record_id) { 5 }

  let(:mock_adapter) { double }
  let(:mock_reference_record) { double(id: mock_reference_record_id) }
  let(:mock_collection_record) do
    double(name: 'mock_collection', partition_for: partition, include_ref_fields: true,
      collection_class: 'Test::Collections::Mock')
  end

  let(:test_reference) do
    mock_reference_class.new(collection_id: collection_id, routing: partition, args: mock_reference_record_id)
  end

  let(:test_model_key) { 'test-model-001' }
  let(:mock_embedding_models) do
    ::ActiveContext::EmbeddingModel.new(
      model_name: test_model_key,
      field: 'embeddings_v1',
      llm_class: Test::MockLlmClass,
      llm_params: { model: test_model_key }
    )
  end

  let(:default_content) { 'content returned in reference method' }
  let(:expected_vectors) { Test::MockLlmClass::MOCK_VECTORS }

  let(:preprocessed_reference) { preprocessed_result[:successful].first }

  subject(:preprocessed_result) { ActiveContext::Reference.preprocess_references([test_reference]) }

  before do
    allow(ActiveContext).to receive(:adapter).and_return(mock_adapter)
    allow(ActiveContext::CollectionCache).to receive(:fetch).and_return(mock_collection_record)
    allow(mock_reference_class.model_klass).to receive(:find_by).and_return(mock_reference_record)

    allow(test_reference).to receive(:indexing_embedding_models).and_return([mock_embedding_models])

    allow(ActiveContext::Logger).to receive(:retryable_exception)
  end

  shared_examples 'skips document creation' do
    it 'does not create documents' do
      expect { preprocessed_reference }.not_to change { test_reference.documents.count }
    end
  end

  shared_examples 'uses the reference content method' do
    it 'generates the content using the specified `content_method`' do
      expect(test_reference).to receive(:embedding_content).once.and_call_original

      preprocessed_result
    end
  end

  shared_examples 'does not use the reference content method' do
    it 'does not generate content using the content_method' do
      expect(test_reference).not_to receive(:embedding_content)

      preprocessed_reference
    end
  end

  shared_examples 'generates and sets embeddings for each document' do
    let(:expected_content_key) { :content }

    it 'generates and sets embeddings for each document' do
      expect(Test::MockLlmClass).to receive(:new).with(
        [expected_content],
        unit_primitive: 'test_unit_primitive',
        user: nil,
        model: test_model_key
      ).and_call_original

      expect(preprocessed_reference.documents).to match_array([{ expected_content_key => expected_content,
                                                                 embeddings_v1: expected_vectors }])
    end
  end

  shared_examples 'generates and sets embeddings for each document and removes the content' do
    it 'generates and sets embeddings for each document and removes the content' do
      expect(Test::MockLlmClass).to receive(:new).with(
        [expected_content],
        unit_primitive: 'test_unit_primitive',
        user: nil,
        model: test_model_key
      ).and_call_original

      expect(preprocessed_reference.documents).to match_array([{ embeddings_v1: expected_vectors }])
    end
  end

  shared_examples 'skips embeddings generation' do
    it 'does not generate embeddings' do
      expect(Test::MockLlmClass).not_to receive(:new)

      expect(preprocessed_reference.documents).to be_empty
    end
  end

  shared_examples 'fails to generate embeddings' do
    it 'results in failures and logs the error' do
      expect(ActiveContext::Logger).to receive(:retryable_exception) do |error, kwargs|
        expect(error.message).to eq(Test::MockLlmClass::NIL_CONTENTS_ERROR_MESSAGE)
        expect(kwargs[:class]).to eq('Class')
      end

      expect { preprocessed_result }.not_to change { test_reference.documents.count }
      expect(preprocessed_result[:successful]).to be_empty
      expect(preprocessed_result[:failed]).to eq([test_reference])
    end
  end

  describe '.apply_embeddings_with_model_redesign' do
    context 'when :content_method is passed and defined' do
      context 'when no documents are present' do
        it 'creates a single document' do
          expect { preprocessed_result }.to change { test_reference.documents.count }.by(1)
        end

        it_behaves_like 'uses the reference content method'

        it_behaves_like 'generates and sets embeddings for each document' do
          let(:expected_content) { default_content }
        end
      end

      context 'when documents are present' do
        context 'when :content_field is not passed' do
          context 'when documents have content populated' do
            before do
              test_reference.documents << { content: 'Other content' }
            end

            it_behaves_like 'skips document creation'

            it_behaves_like 'does not use the reference content method'

            it_behaves_like 'generates and sets embeddings for each document' do
              let(:expected_content) { 'Other content' }
            end
          end

          context 'when documents do not have content populated' do
            before do
              test_reference.documents << {}
            end

            it_behaves_like 'skips document creation'

            it_behaves_like 'uses the reference content method'

            it_behaves_like 'generates and sets embeddings for each document' do
              let(:expected_content) { default_content }
            end
          end

          context 'when :remove_content_field is set to true' do
            let(:mock_reference_class) do
              Class.new(Test::References::MockWithDatabaseRecord) do
                include ::ActiveContext::Preprocessors::Embeddings

                add_preprocessor :embeddings do |refs|
                  apply_embeddings_with_model_redesign(
                    refs: refs, content_method: :embedding_content,
                    remove_content: true,
                    unit_primitive: 'test_unit_primitive'
                  )
                end

                def embedding_content
                  'content returned in reference method'
                end
              end
            end

            before do
              test_reference.documents << {}
            end

            it_behaves_like 'generates and sets embeddings for each document and removes the content' do
              let(:expected_content) { default_content }
            end
          end
        end

        context 'when :content_field is passed' do
          let(:mock_reference_class) do
            Class.new(Test::References::MockWithDatabaseRecord) do
              include ::ActiveContext::Preprocessors::Embeddings

              add_preprocessor :embeddings do |refs|
                apply_embeddings_with_model_redesign(
                  refs: refs, content_field: :other_content,
                  content_method: :embedding_content, unit_primitive: 'test_unit_primitive'
                )
              end

              def embedding_content
                'content returned in reference method'
              end
            end
          end

          context 'when documents have the content field populated' do
            before do
              test_reference.documents << { other_content: 'Some other content' }
            end

            it_behaves_like 'skips document creation'

            it_behaves_like 'does not use the reference content method'

            it_behaves_like 'generates and sets embeddings for each document' do
              let(:expected_content) { 'Some other content' }
              let(:expected_content_key) { :other_content }
            end
          end

          context 'when documents do not have the content field populated' do
            before do
              test_reference.documents << {}
            end

            it_behaves_like 'skips document creation'

            it_behaves_like 'uses the reference content method'

            it_behaves_like 'generates and sets embeddings for each document' do
              let(:expected_content) { default_content }
              let(:expected_content_key) { :other_content }
            end
          end

          context 'when :remove_content is set to true' do
            let(:mock_reference_class) do
              Class.new(Test::References::MockWithDatabaseRecord) do
                include ::ActiveContext::Preprocessors::Embeddings

                add_preprocessor :embeddings do |refs|
                  apply_embeddings_with_model_redesign(
                    refs: refs, content_field: :other_content,
                    content_method: :embedding_content,
                    remove_content: true,
                    unit_primitive: 'test_unit_primitive'
                  )
                end

                def embedding_content
                  'content returned in reference method'
                end
              end
            end

            before do
              test_reference.documents << { other_content: 'Some other content' }
            end

            it_behaves_like 'generates and sets embeddings for each document and removes the content' do
              let(:expected_content) { 'Some other content' }
            end
          end
        end
      end
    end

    context 'when :content_method is passed but not defined' do
      let(:mock_reference_class) do
        Class.new(Test::References::MockWithDatabaseRecord) do
          include ::ActiveContext::Preprocessors::Embeddings

          add_preprocessor :embeddings do |refs|
            apply_embeddings_with_model_redesign(
              refs: refs, content_method: :embedding_content,
              unit_primitive: 'test_unit_primitive'
            )
          end
        end
      end

      it_behaves_like 'skips document creation'

      it_behaves_like 'skips embeddings generation'
    end

    context 'when :content_method is not passed' do
      let(:mock_reference_class) do
        Class.new(Test::References::MockWithDatabaseRecord) do
          include ::ActiveContext::Preprocessors::Embeddings

          add_preprocessor :embeddings do |refs|
            apply_embeddings_with_model_redesign(refs: refs, unit_primitive: 'test_unit_primitive')
          end
        end
      end

      context 'when no documents are present' do
        it_behaves_like 'skips document creation'

        it_behaves_like 'skips embeddings generation'
      end

      context 'when documents are present' do
        context 'when :content_field is not passed' do
          context 'when documents have content populated' do
            before do
              test_reference.documents << { content: 'Other content' }
            end

            it_behaves_like 'skips document creation'

            it_behaves_like 'generates and sets embeddings for each document' do
              let(:expected_content) { 'Other content' }
            end
          end

          context 'when documents do not have content populated' do
            before do
              test_reference.documents << {}
            end

            it_behaves_like 'fails to generate embeddings'
          end
        end

        context 'when :content_field is passed' do
          let(:mock_reference_class) do
            Class.new(Test::References::MockWithDatabaseRecord) do
              include ::ActiveContext::Preprocessors::Embeddings

              add_preprocessor :embeddings do |refs|
                apply_embeddings_with_model_redesign(
                  refs: refs, content_field: :other_content,
                  unit_primitive: 'test_unit_primitive'
                )
              end
            end
          end

          context 'when documents have the content field populated' do
            before do
              test_reference.documents << { other_content: 'Some other content' }
            end

            it_behaves_like 'skips document creation'

            it_behaves_like 'generates and sets embeddings for each document' do
              let(:expected_content) { 'Some other content' }
              let(:expected_content_key) { :other_content }
            end
          end

          context 'when documents do not have the content field populated' do
            before do
              test_reference.documents << {}
            end

            it_behaves_like 'fails to generate embeddings'
          end
        end
      end
    end
  end
end
