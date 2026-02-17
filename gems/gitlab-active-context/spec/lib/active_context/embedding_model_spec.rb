# frozen_string_literal: true

RSpec.describe ActiveContext::EmbeddingModel do
  let(:field) { 'embeddings_v123' }
  let(:model_name) { 'embedding model 123' }
  let(:model) { 'model-123' }

  let(:llm_class) { Test::MockLlmClass }
  let(:llm_params) { { model: model } }

  let(:embedding_model) do
    described_class.new(
      model_name: model_name,
      field: field,
      llm_class: llm_class,
      llm_params: llm_params
    )
  end

  describe 'accessors' do
    it 'returns the expected embedding model info' do
      expect(embedding_model.model_name).to eq(model_name)
      expect(embedding_model.field).to eq(field)
      expect(embedding_model.llm_class).to eq(llm_class)
      expect(embedding_model.llm_params).to eq(llm_params)
    end
  end

  describe '#generate_embeddings' do
    before do
      allow(llm_class).to receive(:new).and_call_original
    end

    subject(:generate_embeddings) do
      embedding_model.generate_embeddings(
        content, unit_primitive: unit_primitive, user: user
      )
    end

    let(:unit_primitive) { 'mock_unit_primitive' }
    let(:user) { double("User") }

    let(:content) { %w[one two three] }
    let(:embeddings) { [[1, 1, 1], [2, 2, 2], [3, 3, 3]] }

    shared_examples 'generates embeddings successfully' do
      before do
        allow_any_instance_of(llm_class).to receive(:execute).and_return(embeddings)
      end

      it 'initializes the llm_class with the expected params and calls `execute`' do
        expect(llm_class).to receive(:new).with(
          contents_for_llm, unit_primitive: unit_primitive, user: user, model: model
        )

        expect_any_instance_of(llm_class).to receive(:execute).and_return(embeddings)

        generate_embeddings
      end
    end

    it_behaves_like 'generates embeddings successfully' do
      let(:contents_for_llm) { content }
    end

    context 'with a single content param' do
      let(:content) { 'one' }
      let(:embeddings) { [[1, 1, 1]] }

      it_behaves_like 'generates embeddings successfully' do
        let(:contents_for_llm) { [content] }
      end
    end

    context 'when llm class initialization fails' do
      let(:llm_params) { { model: model, unexpected_param: 'unexpected param' } }

      it 'raises an error' do
        expect { generate_embeddings }.to raise_error(
          described_class::LlmClassError,
          "Error initializing Test::MockLlmClass: " \
            "ArgumentError - unknown keyword: :unexpected_param"
        )
      end
    end

    context 'when llm class does not respond to `execute`' do
      let(:llm_class) do
        Class.new do
          def initialize(contents, unit_primitive:, user:, model:); end
        end
      end

      it 'raises an error' do
        expect { generate_embeddings }.to raise_error(
          described_class::LlmClassError,
          "Instance of #{llm_class} does not respond to `execute`."
        )
      end
    end
  end
end
