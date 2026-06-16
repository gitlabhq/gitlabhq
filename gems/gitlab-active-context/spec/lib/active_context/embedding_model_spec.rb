# frozen_string_literal: true

RSpec.describe ActiveContext::EmbeddingModel do
  let(:field) { 'embeddings_v123' }
  let(:model_ref) { 'model-123' }
  let(:model_type) { 'gitlab' }

  let(:llm_class) { Test::MockLlmClass }

  let(:embedding_model) do
    described_class.new(
      field: field,
      model_ref: model_ref,
      model_type: model_type,
      llm_class: llm_class
    )
  end

  describe 'accessors' do
    it 'returns the expected embedding model info' do
      expect(embedding_model.field).to eq(field.to_sym)
      expect(embedding_model.model_ref).to eq(model_ref)
      expect(embedding_model.model_type).to eq(model_type.to_sym)
      expect(embedding_model.llm_class).to eq(llm_class)
      expect(embedding_model.llm_params).to eq({})
      expect(embedding_model.dimensions).to be_nil
    end

    context 'when dimensions is set' do
      let(:embedding_model) do
        described_class.new(
          field: field,
          model_ref: model_ref,
          model_type: model_type,
          llm_class: llm_class,
          dimensions: dimensions
        )
      end

      context 'with valid dimensions' do
        where(:dimensions) { [8, '8'] }

        with_them do
          it 'returns the correct dimensions property' do
            expect(embedding_model.dimensions).to eq(8)
          end
        end
      end

      context 'with invalid dimensions' do
        let(:dimensions) { 'str' }

        it 'raises an error' do
          expect { embedding_model }.to raise_error(ArgumentError, /invalid value for Integer/)
        end
      end
    end
  end

  describe '#model_key' do
    it 'is built from the model_type and model_ref' do
      expect(embedding_model.model_key).to eq("gitlab__model-123")
    end
  end

  describe '#generate_embeddings' do
    before do
      allow(::ActiveContext::Logger).to receive(:info)

      allow(llm_class).to receive(:new).and_call_original
    end

    subject(:generate_embeddings) do
      embedding_model.generate_embeddings(content, user: user)
    end

    let(:user) { double("User") }

    let(:content) { %w[one two three] }

    shared_examples 'generates embeddings successfully' do
      before do
        allow(llm_class).to receive(:new).and_call_original
      end

      it 'initializes the llm_class with the expected params and calls `execute`' do
        expected_args = expected_extra_args
        expected_args[:dimensions] = expected_dimensions_arg if expected_dimensions_arg
        expect(llm_class).to receive(:new).with(
          contents_for_llm, user: user, **expected_args
        )

        embeddings = generate_embeddings
        expect(embeddings.length).to eq(contents_for_llm.length)

        expected_content_embeddings_count = expected_dimensions_arg || llm_class::DEFAULT_DIMENSIONS
        expect(embeddings.first.length).to eq(expected_content_embeddings_count)
      end

      it 'logs the embeddings generation' do
        expect(::ActiveContext::Logger).to receive(:info).with(
          message: "generate embeddings",
          model: 'gitlab__model-123',
          status: "start",
          class: "ActiveContext::EmbeddingModel"
        )
        expect(::ActiveContext::Logger).to receive(:info).with(
          message: "generate embeddings",
          model: 'gitlab__model-123',
          status: "done",
          class: "ActiveContext::EmbeddingModel"
        )

        generate_embeddings
      end
    end

    it_behaves_like 'generates embeddings successfully' do
      let(:contents_for_llm) { content }
      let(:expected_extra_args) { {} }
      let(:expected_dimensions_arg) { nil }
    end

    context 'with a single content param' do
      let(:content) { 'one' }
      let(:embeddings) { [[1, 1, 1]] }

      it_behaves_like 'generates embeddings successfully' do
        let(:contents_for_llm) { [content] }
        let(:expected_extra_args) { {} }
        let(:expected_dimensions_arg) { nil }
      end
    end

    context 'when dimensions is set' do
      let(:dimensions) { 8 }
      let(:embedding_model) do
        described_class.new(
          field: field,
          model_ref: model_ref,
          model_type: model_type,
          llm_class: llm_class,
          dimensions: dimensions
        )
      end

      it_behaves_like 'generates embeddings successfully' do
        let(:contents_for_llm) { content }
        let(:expected_extra_args) { {} }
        let(:expected_dimensions_arg) { dimensions }
      end

      context 'with non-positive dimensions' do
        where(:dimensions) do
          [-1, 0]
        end

        with_them do
          it 'raises an error' do
            expect { generate_embeddings }.to raise_error(
              described_class::Error,
              "`dimensions` parameter must be a whole number greater than `0`"
            )
          end
        end
      end
    end

    context 'when llm_params is set' do
      let(:llm_params) { { abc: "extra-params" } }
      let(:embedding_model) do
        described_class.new(
          field: field,
          model_ref: model_ref,
          model_type: model_type,
          llm_class: llm_class,
          llm_params: llm_params
        )
      end

      it 'returns the correct llm_params property' do
        expect(embedding_model.llm_params).to eq(llm_params)
      end

      it_behaves_like 'generates embeddings successfully' do
        let(:contents_for_llm) { content }
        let(:expected_extra_args) { llm_params }
        let(:expected_dimensions_arg) { nil }
      end

      context 'when llm_params has some unexpected fields' do
        let(:llm_params) { { abc: "extra-params", unexpected_param: 'unexpected param' } }

        it 'raises an error' do
          expect { generate_embeddings }.to raise_error(
            described_class::Error,
            "Error initializing Test::MockLlmClass: " \
              "ArgumentError - unknown keyword: :unexpected_param"
          )
        end
      end
    end

    context 'when llm class does not respond to `execute`' do
      let(:llm_class) do
        Class.new do
          def initialize(contents, user:, dimensions: nil, abc: nil); end
        end
      end

      it 'raises an error' do
        expect { generate_embeddings }.to raise_error(
          described_class::Error,
          "Instance of #{llm_class} does not respond to `execute`."
        )
      end
    end
  end
end
