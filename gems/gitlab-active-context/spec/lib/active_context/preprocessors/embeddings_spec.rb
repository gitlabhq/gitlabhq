# frozen_string_literal: true

RSpec.describe ActiveContext::Preprocessors::Embeddings do
  let(:reference_class) do
    Class.new(Test::References::MockWithDatabaseRecord) do
      include ::ActiveContext::Preprocessors::Embeddings

      add_preprocessor :embeddings do |refs|
        apply_embeddings(refs: refs, content_method: :embedding_content, unit_primitive: 'test_unit_primitive')
      end

      def embedding_content
        'Some content'
      end
    end
  end

  let(:preprocessed_result) { ActiveContext::Reference.preprocess_references([reference]) }

  let(:reference) { reference_class.new(collection_id: collection_id, routing: partition, args: object_id) }

  let(:mock_adapter) { double }
  let(:mock_collection) { double(name: collection_name, partition_for: partition, include_ref_fields: true) }
  let(:mock_object) { double(id: object_id) }
  let(:mock_relation) { double(find_by: mock_object) }
  let(:mock_embedding_version) { { field: :embedding, model: nil, class: Test::Embeddings, batch_size: 10 } }

  let(:partition) { 2 }
  let(:collection_id) { 1 }
  let(:object_id) { 5 }
  let(:collection_name) { 'mock_collection' }
  let(:vectors) { [1.0, 2.0] }
  let(:unit_primitive) { 'test_unit_primitive' }
  let(:vertex_blank_error) { StandardError.new('The text content is empty.') }

  before do
    allow(ActiveContext).to receive(:adapter).and_return(mock_adapter)
    allow(ActiveContext::CollectionCache).to receive(:fetch).and_return(mock_collection)
    allow(reference_class).to receive(:model_klass).and_return(mock_relation)
    allow(reference).to receive(:embedding_versions).and_return([mock_embedding_version])
    allow(Test::Embeddings).to receive(:generate_embeddings) do |contents, **_kwargs|
      raise vertex_blank_error if contents.any?(&:nil?) # this is what vertex returns when the content is empty

      Array.new(contents.size, vectors)
    end
    allow(ActiveContext::Logger).to receive(:retryable_exception)
  end

  subject(:preprocessed_reference) { preprocessed_result[:successful].first }

  describe '.apply_embeddings' do
    context 'when :content_method is passed and defined' do
      context 'when no documents are present' do
        it 'creates a single document' do
          expect { preprocessed_reference }.to change { reference.documents.count }.by(1)
        end

        it 'generates the content using the content_method' do
          expect(reference).to receive(:embedding_content).once.and_call_original

          preprocessed_reference
        end

        it 'generates and sets embeddings for each document' do
          expect(Test::Embeddings).to receive(:generate_embeddings)
            .once
            .with(
              ['Some content'],
              model: nil,
              unit_primitive: unit_primitive,
              user: nil,
              batch_size: 10
            ).and_return([vectors])

          expect(preprocessed_reference.documents).to match_array([{ embedding: vectors }])
        end
      end

      context 'when documents are present' do
        context 'when :content_field is not passed (default is used)' do
          context 'when documents have content populated' do
            before do
              reference.documents << { content: 'Other content' }
            end

            it 'does not create documents' do
              expect { preprocessed_reference }.not_to change { reference.documents.count }
            end

            it 'does not generate content using the content_method' do
              expect(reference).not_to receive(:embedding_content)

              preprocessed_reference
            end

            it 'generates and sets embeddings for each document' do
              expect(Test::Embeddings).to receive(:generate_embeddings)
                .once
                .with(
                  ['Other content'],
                  model: nil,
                  unit_primitive: unit_primitive,
                  user: nil,
                  batch_size: 10
                ).and_return([vectors])

              expect(preprocessed_reference.documents).to match_array([{ embedding: vectors }])
            end
          end

          context 'when documents do not have content populated' do
            before do
              reference.documents << {}
            end

            it 'does not create documents' do
              expect { preprocessed_reference }.not_to change { reference.documents.count }
            end

            it 'generates the content using the content_method' do
              expect(reference).to receive(:embedding_content).once.and_call_original

              preprocessed_reference
            end

            it 'generates and sets embeddings for each document' do
              expect(Test::Embeddings).to receive(:generate_embeddings)
                .once
                .with(
                  ['Some content'],
                  model: nil,
                  unit_primitive: unit_primitive,
                  user: nil,
                  batch_size: 10
                ).and_return([vectors])

              expect(preprocessed_reference.documents).to match_array([{ embedding: vectors }])
            end
          end

          context 'when :remove_content_field is set to false' do
            let(:reference_class) do
              Class.new(Test::References::MockWithDatabaseRecord) do
                include ::ActiveContext::Preprocessors::Embeddings

                add_preprocessor :embeddings do |refs|
                  apply_embeddings(refs: refs, content_method: :embedding_content, remove_content: false,
                    unit_primitive: 'test_unit_primitive')
                end

                def embedding_content
                  'Some content'
                end
              end
            end

            before do
              reference.documents << {}
            end

            it 'keeps the content field in the document' do
              expect(preprocessed_reference.documents).to match_array([{ content: 'Some content', embedding: vectors }])
            end
          end
        end

        context 'when :content_field is passed' do
          let(:reference_class) do
            Class.new(Test::References::MockWithDatabaseRecord) do
              include ::ActiveContext::Preprocessors::Embeddings

              add_preprocessor :embeddings do |refs|
                apply_embeddings(refs: refs, content_field: :other_field, content_method: :embedding_content,
                  unit_primitive: 'test_unit_primitive')
              end

              def embedding_content
                'Some content'
              end
            end
          end

          context 'when documents have the content field populated' do
            before do
              reference.documents << { other_field: 'Some other content' }
            end

            it 'does not create documents' do
              expect { preprocessed_reference }.not_to change { reference.documents.count }
            end

            it 'does not generate content using the content_method' do
              expect(reference).not_to receive(:embedding_content)

              preprocessed_reference
            end

            it 'generates and sets embeddings for each document' do
              expect(Test::Embeddings).to receive(:generate_embeddings)
                .once
                .with(
                  ['Some other content'],
                  model: nil,
                  unit_primitive: unit_primitive,
                  user: nil,
                  batch_size: 10
                ).and_return([vectors])

              expect(preprocessed_reference.documents).to match_array([{ embedding: vectors }])
            end
          end

          context 'when documents do not have the content field populated' do
            before do
              reference.documents << {}
            end

            it 'does not create documents' do
              expect { preprocessed_reference }.not_to change { reference.documents.count }
            end

            it 'generates the content using the content_method' do
              expect(reference).to receive(:embedding_content).once.and_call_original

              preprocessed_reference
            end

            it 'generates and sets embeddings for each document' do
              expect(Test::Embeddings).to receive(:generate_embeddings)
                .once
                .with(
                  ['Some content'],
                  model: nil,
                  unit_primitive: unit_primitive,
                  user: nil,
                  batch_size: 10
                ).and_return([vectors])

              expect(preprocessed_reference.documents).to match_array([{ embedding: vectors }])
            end
          end

          context 'when :remove_content_field is set to false' do
            let(:reference_class) do
              Class.new(Test::References::MockWithDatabaseRecord) do
                include ::ActiveContext::Preprocessors::Embeddings

                add_preprocessor :embeddings do |refs|
                  apply_embeddings(refs: refs, content_field: :other_field, content_method: :embedding_content,
                    remove_content: false, unit_primitive: 'test_unit_primitive')
                end

                def embedding_content
                  'Some content'
                end
              end
            end

            before do
              reference.documents << {}
            end

            it 'keeps the content field in the document' do
              expected_array = [{ other_field: 'Some content', embedding: vectors }]
              expect(preprocessed_reference.documents).to match_array(expected_array)
            end
          end
        end
      end
    end

    context 'when :content_method is passed but not defined' do
      let(:reference_class) do
        Class.new(Test::References::MockWithDatabaseRecord) do
          include ::ActiveContext::Preprocessors::Embeddings

          add_preprocessor :embeddings do |refs|
            apply_embeddings(refs: refs, content_method: :embedding_content,
              unit_primitive: 'test_unit_primitive')
          end
        end
      end

      it 'does not create documents' do
        expect { preprocessed_reference }.not_to change { reference.documents.count }
      end

      it 'does not generate embeddings' do
        expect(Test::Embeddings).not_to receive(:generate_embeddings)

        expect(preprocessed_reference.documents).to be_empty
      end
    end

    context 'when :content_method is not passed' do
      let(:reference_class) do
        Class.new(Test::References::MockWithDatabaseRecord) do
          include ::ActiveContext::Preprocessors::Embeddings

          add_preprocessor :embeddings do |refs|
            apply_embeddings(refs: refs, unit_primitive: 'test_unit_primitive')
          end
        end
      end

      context 'when no documents are present' do
        it 'does not create documents' do
          expect { preprocessed_reference }.not_to change { reference.documents.count }
        end

        it 'does not generate embeddings' do
          expect(Test::Embeddings).not_to receive(:generate_embeddings)

          expect(preprocessed_reference.documents).to be_empty
        end
      end

      context 'when documents are present' do
        context 'when :content_field is not passed (default is used)' do
          context 'when documents have content populated' do
            before do
              reference.documents << { content: 'Other content' }
            end

            it 'does not create documents' do
              expect { preprocessed_reference }.not_to change { reference.documents.count }
            end

            it 'generates and sets embeddings for each document' do
              expect(Test::Embeddings).to receive(:generate_embeddings)
                .once
                .with(
                  ['Other content'],
                  model: nil,
                  unit_primitive: unit_primitive,
                  user: nil,
                  batch_size: 10
                ).and_return([vectors])

              expect(preprocessed_reference.documents).to match_array([{ embedding: vectors }])
            end
          end

          context 'when documents do not have content populated' do
            before do
              reference.documents << {}
            end

            it 'raises and logs an error because the embedding content cannot be blank' do
              expect(ActiveContext::Logger).to receive(:retryable_exception)
                .with(vertex_blank_error, class: 'Class', refs: anything)

              expect { preprocessed_result }.not_to change { reference.documents.count }
              expect(preprocessed_result[:successful]).to be_empty
              expect(preprocessed_result[:failed]).to eq([reference])
            end
          end
        end

        context 'when :content_field is passed' do
          let(:reference_class) do
            Class.new(Test::References::MockWithDatabaseRecord) do
              include ::ActiveContext::Preprocessors::Embeddings

              add_preprocessor :embeddings do |refs|
                apply_embeddings(refs: refs, content_field: :other_field,
                  unit_primitive: 'test_unit_primitive')
              end
            end
          end

          context 'when documents have the content field populated' do
            before do
              reference.documents << { other_field: 'Some other content' }
            end

            it 'does not create documents' do
              expect { preprocessed_reference }.not_to change { reference.documents.count }
            end

            it 'generates and sets embeddings for each document' do
              expect(Test::Embeddings).to receive(:generate_embeddings)
                .once.with(
                  ['Some other content'],
                  model: nil,
                  unit_primitive: unit_primitive,
                  user: nil,
                  batch_size: 10
                ).and_return([vectors])

              expect(preprocessed_reference.documents).to match_array([{ embedding: vectors }])
            end
          end

          context 'when documents do not have the content field populated' do
            before do
              reference.documents << {}
            end

            it 'raises and logs an error because the embedding content cannot be blank' do
              expect(ActiveContext::Logger).to receive(:retryable_exception)
                .with(vertex_blank_error, class: 'Class', refs: anything)

              expect { preprocessed_result }.not_to change { reference.documents.count }
              expect(preprocessed_result[:successful]).to be_empty
              expect(preprocessed_result[:failed]).to eq([reference])
            end
          end
        end
      end
    end

    describe 'embedding versions' do
      shared_examples 'has an EmbeddingsClassError' do
        # An ActiveContext::Embeddings::EmbeddingsClassError is raised here
        # But all StandardError types are caught in `with_batch_handling`
        # This will be addressed in https://gitlab.com/gitlab-org/gitlab/-/issues/552302
        it 'raises an error', skip: 'error is still handled in `with_batch_handling`' do
          expect { preprocessed_result }.to raise_error(
            ActiveContext::Embeddings::EmbeddingsClassError,
            expected_error_message
          )
        end

        # TODO: remove after https://gitlab.com/gitlab-org/gitlab/-/issues/552302
        it 'logs the error' do
          expect(ActiveContext::Logger).to receive(:retryable_exception) do |error_arg|
            expect(error_arg.class).to eq ActiveContext::Embeddings::EmbeddingsClassError
            expect(error_arg.message).to eq expected_error_message
          end

          expect(preprocessed_result[:successful]).to be_empty
          expect(preprocessed_result[:failed]).to eq([reference])
        end
      end

      context 'when embedding version class is not defined' do
        let(:mock_embedding_version) { { field: :embedding, model: nil } }

        it_behaves_like 'has an EmbeddingsClassError' do
          let(:expected_error_message) { "No `class` specified for model version `embedding`." }
        end
      end

      context 'when embedding version class does not implement a `generate_embeddings` class method' do
        let(:mock_embeddings_class) { Class.new(Object) }
        let(:mock_embedding_version) { { field: :embedding, model: nil, class: mock_embeddings_class } }

        it_behaves_like 'has an EmbeddingsClassError' do
          let(:expected_error_message) do
            "Specified class for model version `embedding` must have a `generate_embeddings` class method."
          end
        end
      end

      context "when the embedding version class's generate_embeddings method expects the wrong arguments" do
        let(:mock_embeddings_class) do
          Class.new(Test::Embeddings) do
            def self.generate_embeddings(the, wrong:, params:); end
          end
        end

        let(:mock_embedding_version) { { field: :embedding, model: nil, class: mock_embeddings_class } }

        it_behaves_like 'has an EmbeddingsClassError' do
          let(:expected_error_message) do
            "`#{mock_embeddings_class}.generate_embeddings` does not have the correct parameters: " \
              "missing keywords: :wrong, :params"
          end
        end
      end
    end
  end
end
