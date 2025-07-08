# frozen_string_literal: true

RSpec.describe ActiveContext::Embeddings do
  describe '.generate_embeddings' do
    let(:contents) { ['contents-for-embeddings'] }
    let(:unit_primitive) { 'dummy-unit-primitive' }
    let(:user) { double("user") }
    let(:batch_size) { 12 }
    let(:embeddings_version) do
      { model: 'dummy-model', field: 'dummy-field', class: Test::Embeddings }
    end

    subject(:generate_embeddings) do
      described_class.generate_embeddings(
        contents,
        version: embeddings_version,
        unit_primitive: unit_primitive,
        user: user,
        batch_size: batch_size
      )
    end

    it 'calls the embeddings class specified in the version' do
      expect(Test::Embeddings).to receive(:generate_embeddings).with(
        contents,
        model: embeddings_version[:model],
        unit_primitive: unit_primitive,
        user: user,
        batch_size: batch_size
      )

      generate_embeddings
    end

    context 'when a single content input given' do
      let(:contents) { 'non-array input' }

      it 'wraps the input in an array' do
        expect(Test::Embeddings).to receive(:generate_embeddings).with(
          [contents],
          model: embeddings_version[:model],
          unit_primitive: unit_primitive,
          user: user,
          batch_size: batch_size
        )

        generate_embeddings
      end
    end

    context 'when class is not specified in the version' do
      let(:embeddings_version) do
        { model: 'dummy-model', field: 'dummy-field' }
      end

      it 'raises an error' do
        expect { generate_embeddings }.to raise_error(
          described_class::EmbeddingsClassError,
          "No `class` specified for model version `dummy-field`."
        )
      end
    end

    context 'when embeddings class does not have a `generate_embeddings` method' do
      let(:embeddings_class) { Class.new(Object) }
      let(:embeddings_version) do
        { model: 'dummy-model', field: 'dummy-field', class: embeddings_class }
      end

      it 'raises an error' do
        expect { generate_embeddings }.to raise_error(
          described_class::EmbeddingsClassError,
          "Specified class for model version `dummy-field` must have a `generate_embeddings` class method."
        )
      end
    end

    context "when the embeddings class' `generate_embeddings` method does not have the right parameters" do
      let(:embeddings_class) do
        Class.new(Test::Embeddings) do
          def self.generate_embeddings(the, wrong:, params:); end
        end
      end

      let(:embeddings_version) do
        { model: 'dummy-model', field: 'dummy-field', class: embeddings_class }
      end

      it 'raises an error' do
        expect { generate_embeddings }.to raise_error(
          described_class::EmbeddingsClassError,
          "`#{embeddings_class}.generate_embeddings` does not have the correct parameters: " \
            "missing keywords: :wrong, :params"
        )
      end
    end
  end
end
