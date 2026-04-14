# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe ActiveContext::Concerns::Collection do
  let(:collection_class) { Test::Collections::Mock }
  let(:mock_object) { double(id: 123) }
  let(:collection_record) { double(id: 456) }
  let(:reference_instance) { instance_double(Test::References::Mock) }
  let(:mock_adapter) { double }
  let(:search_results) { double(ids: %w[1 2 3], user: user) }
  let(:user) { double }

  before do
    allow(ActiveContext::CollectionCache).to receive(:fetch)
      .with(collection_class.collection_name)
      .and_return(collection_record)
    allow(ActiveContext).to receive(:adapter).and_return(mock_adapter)
  end

  describe '.track!' do
    it 'delegates to ActiveContext::Tracker' do
      objects = [mock_object]

      expect(ActiveContext::Tracker).to receive(:track!).with(objects, collection: collection_class, queue: nil)

      collection_class.track!(*objects)
    end

    it 'passes queue parameter to ActiveContext::Tracker' do
      objects = [mock_object]
      queue = double

      expect(ActiveContext::Tracker).to receive(:track!).with(objects, collection: collection_class, queue: queue)

      collection_class.track!(*objects, queue: queue)
    end
  end

  describe '.search' do
    it 'delegates to ActiveContext adapter' do
      query = 'test query'

      expect(mock_adapter).to receive(:search).with(query: query, user: user, collection: collection_class)

      collection_class.search(user: user, query: query)
    end
  end

  describe '.collection_record' do
    it 'fetches from CollectionCache' do
      expect(ActiveContext::CollectionCache).to receive(:fetch).with(collection_class.collection_name)

      collection_class.collection_record
    end
  end

  describe '.redact_unauthorized_results!' do
    let(:object1) { double(id: '1') }
    let(:object2) { double(id: '2') }
    let(:object3) { double(id: '3') }
    let(:ids) { %w[2 3 1] }
    let(:objects) { [object1, object2, object3] }
    let(:search_results) { double(ids: ids, user: user) }

    before do
      allow(collection_class).to receive(:ids_to_objects).with(ids).and_return(objects)
    end

    it 'preserves the order of IDs in the authorized results' do
      allow(collection_class).to receive(:authorized_to_see_object?).with(user, object1).and_return(true)
      allow(collection_class).to receive(:authorized_to_see_object?).with(user, object2).and_return(true)
      allow(collection_class).to receive(:authorized_to_see_object?).with(user, object3).and_return(false)

      result = collection_class.redact_unauthorized_results!(search_results)

      expect(result).to eq([object2, object1])
    end

    it 'filters out unauthorized results' do
      allow(collection_class).to receive(:authorized_to_see_object?).with(user, object1).and_return(false)
      allow(collection_class).to receive(:authorized_to_see_object?).with(user, object2).and_return(true)
      allow(collection_class).to receive(:authorized_to_see_object?).with(user, object3).and_return(false)

      result = collection_class.redact_unauthorized_results!(search_results)

      expect(result).to eq([object2])
    end
  end

  describe 'all embedding models' do
    shared_examples 'embedding_model' do
      subject(:embedding_model) { collection_class.public_send(embedding_model_key) }

      context 'when collection_record is nil' do
        let(:collection_record) { nil }

        it { is_expected.to be_nil }
      end

      context "when collection record's model metadata is nil" do
        let(:collection_record) do
          double("Collection", id: 123, embedding_model_key => nil)
        end

        it { is_expected.to be_nil }
      end

      context "when the collection record's model metadata is set" do
        before do
          allow(model_selector_class).to receive(:for).and_call_original
        end

        let(:model_selector_class) { collection_class.embedding_model_selector }
        let(:model_metadata) { { model: 'some-model', field: 'some-field' } }
        let(:collection_record) do
          double(
            "Collection",
            id: 123,
            embedding_model_key => { model: 'some-model', field: 'some-field' }
          )
        end

        it "builds an embedding_model object through the embedding_model_selector" do
          expect(model_selector_class).to receive(:for).with(
            model_metadata, **expected_custom_build_params
          )

          embedding_model
        end
      end
    end

    describe '#current_indexing_embedding_model' do
      it_behaves_like 'embedding_model' do
        let(:embedding_model_key) { :current_indexing_embedding_model }
        let(:expected_custom_build_params) { {} }
      end
    end

    describe '#next_indexing_embedding_model' do
      it_behaves_like 'embedding_model' do
        let(:embedding_model_key) { :next_indexing_embedding_model }
        let(:expected_custom_build_params) { {} }
      end
    end

    describe '#search_embedding_model' do
      it_behaves_like 'embedding_model' do
        let(:embedding_model_key) { :search_embedding_model }
        let(:expected_custom_build_params) { { search: true } }
      end
    end
  end

  describe 'indexing embedding models' do
    let(:current_indexing_embedding_model) do
      ::ActiveContext::EmbeddingModel.new(
        model_name: 'some-model-01',
        field: 'current_model_field',
        llm_class: Test::MockLlmClass,
        llm_params: {}
      )
    end

    let(:next_indexing_embedding_model) do
      ::ActiveContext::EmbeddingModel.new(
        model_name: 'some-model-02',
        field: 'next_model_field',
        llm_class: Test::MockLlmClass,
        llm_params: {}
      )
    end

    before do
      allow(collection_class).to receive_messages(
        current_indexing_embedding_model: current_indexing_embedding_model,
        next_indexing_embedding_model: next_indexing_embedding_model
      )
    end

    describe '.indexing_embedding_models' do
      it 'returns the current and next indexing embedding models' do
        expect(collection_class.indexing_embedding_models).to eq(
          [current_indexing_embedding_model, next_indexing_embedding_model]
        )
      end
    end

    describe '.indexing_embedding_fields' do
      it 'returns the current and next indexing fields' do
        expect(collection_class.indexing_embedding_fields).to eq(%w[current_model_field next_model_field])
      end
    end
  end

  describe '#references' do
    let(:collection_instance) { collection_class.new(mock_object) }

    before do
      allow(collection_class).to receive(:routing).with(mock_object).and_return(123)
      allow(Test::References::Mock).to receive(:serialize).with(collection_id: 456, routing: 123,
        data: mock_object).and_return(reference_instance)
    end

    it 'creates references for the object' do
      expect(collection_instance.references).to eq([reference_instance])
    end

    context 'with multiple reference classes' do
      let(:reference_instance2) { instance_double(Test::References::Mock) }
      let(:reference_class2) { class_double(Test::References::Mock) }

      before do
        allow(collection_class).to receive(:reference_klasses).and_return([Test::References::Mock, reference_class2])
        allow(reference_class2).to receive(:serialize).with(collection_id: 456, routing: 123,
          data: mock_object).and_return(reference_instance2)
      end

      it 'creates references for each reference class' do
        expect(collection_instance.references).to eq([reference_instance, reference_instance2])
      end
    end
  end

  describe '.reference_klasses' do
    context 'when reference_klass is defined' do
      it 'returns an array with the reference_klass' do
        expect(collection_class.reference_klasses).to eq([Test::References::Mock])
      end
    end

    context 'when reference_klass is not defined' do
      let(:invalid_collection_class) do
        Class.new do
          include ActiveContext::Concerns::Collection

          def self.reference_klass
            nil
          end
        end
      end

      it 'raises NotImplementedError' do
        expect do
          invalid_collection_class.reference_klasses
        end.to raise_error(NotImplementedError,
          /should define reference_klasses or reference_klass/)
      end
    end
  end

  describe 'required interface methods' do
    let(:base_collection_class) do
      Class.new do
        include ActiveContext::Concerns::Collection
      end
    end

    it 'requires collection_name to be implemented' do
      expect { base_collection_class.collection_name }.to raise_error(NotImplementedError)
    end

    it 'requires queue to be implemented' do
      expect { base_collection_class.queue }.to raise_error(NotImplementedError)
    end

    it 'requires routing to be implemented' do
      expect { base_collection_class.routing(nil) }.to raise_error(NotImplementedError)
    end

    it 'requires ids_to_objects to be implemented' do
      expect { base_collection_class.ids_to_objects(nil) }.to raise_error(NotImplementedError)
    end

    it 'requires embedding_model_selector to be implemented' do
      expect { base_collection_class.embedding_model_selector }.to raise_error(NotImplementedError)
    end
  end

  describe '.backfill_queue' do
    context 'when backfill_queue is not overridden' do
      it 'defaults to the main queue' do
        expect(collection_class.backfill_queue).to eq(collection_class.queue)
      end
    end

    context 'when backfill_queue is overridden' do
      let(:custom_backfill_queue) { double }
      let(:collection_with_custom_backfill) do
        Class.new do
          include ActiveContext::Concerns::Collection

          def self.queue
            'main_queue'
          end

          def self.backfill_queue
            'custom_backfill_queue'
          end
        end
      end

      it 'returns the custom backfill queue' do
        expect(collection_with_custom_backfill.backfill_queue).to eq('custom_backfill_queue')
      end
    end
  end
end
