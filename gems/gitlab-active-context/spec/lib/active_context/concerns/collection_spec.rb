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

      expect(ActiveContext::Tracker).to receive(:track!).with(objects, collection: collection_class)

      collection_class.track!(*objects)
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
  end
end
