# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Concerns::Executor do
  let(:name) { 'test_collection' }
  let(:full_name) { 'prefixed_test_collection' }
  let(:number_of_partitions) { 5 }
  let(:fields) { [{ name: 'field1', type: 'string' }] }

  # Create a test class that includes the executor module
  let(:test_class) do
    Class.new do
      include ActiveContext::Databases::Concerns::Executor

      def do_create_collection(name:, number_of_partitions:, fields:)
        # Mock implementation for testing
      end
    end
  end

  # Create an incomplete class that doesn't implement the abstract methods
  let(:incomplete_class) do
    Class.new do
      include ActiveContext::Databases::Concerns::Executor
      # Intentionally not implementing do_create_collection or do_drop_collection
    end
  end

  let(:adapter) { double('Adapter', connection: connection) }
  let(:connection) { double('Connection', collections: collections) }
  let(:collections) { double('Collections') }
  let(:collection) { double('Collection') }

  subject(:executor) { test_class.new(adapter) }

  describe '#initialize' do
    it 'sets the adapter attribute' do
      expect(executor.adapter).to eq(adapter)
    end
  end

  describe '#create_collection' do
    let(:mock_builder) { double('CollectionBuilder', fields: fields) }

    before do
      stub_const('ActiveContext::Databases::CollectionBuilder', Class.new)
      allow(ActiveContext::Databases::CollectionBuilder).to receive(:new).and_return(mock_builder)

      allow(adapter).to receive(:full_collection_name).with(name).and_return(full_name)
      allow(executor).to receive(:do_create_collection)
      allow(executor).to receive(:create_collection_record)
    end

    it 'creates a collection with the correct parameters' do
      expect(adapter).to receive(:full_collection_name).with(name).and_return(full_name)
      expect(executor).to receive(:do_create_collection).with(
        name: full_name,
        number_of_partitions: number_of_partitions,
        fields: fields,
        options: {}
      )
      expect(executor).to receive(:create_collection_record).with(full_name, number_of_partitions, {})

      executor.create_collection(name, number_of_partitions: number_of_partitions)
    end

    it 'yields the builder if a block is given' do
      expect(mock_builder).to receive(:add_field).with('name', 'string')

      executor.create_collection(name, number_of_partitions: number_of_partitions) do |b|
        b.add_field('name', 'string')
      end
    end
  end

  describe '#create_collection_record' do
    it 'creates or updates a collection record with the correct attributes' do
      expect(collections).to receive(:find_or_initialize_by).with(name: name).and_return(collection)
      expect(collection).to receive(:update)
        .with(number_of_partitions: number_of_partitions, include_ref_fields: true)
      expect(collection).to receive(:save!)

      executor.send(:create_collection_record, name, number_of_partitions, {})
    end

    it 'sets include_ref_fields if passed in' do
      expect(collections).to receive(:find_or_initialize_by).with(name: name).and_return(collection)
      expect(collection).to receive(:update)
        .with(number_of_partitions: number_of_partitions, include_ref_fields: false)
      expect(collection).to receive(:save!)

      executor.send(:create_collection_record, name, number_of_partitions, { include_ref_fields: false })
    end
  end

  describe '#drop_collection' do
    before do
      allow(adapter).to receive(:full_collection_name).with(name).and_return(full_name)
    end

    context 'when collection exists' do
      before do
        allow(collections).to receive(:find_by).with(name: full_name).and_return(collection)
      end

      it 'drops a collection with the correct parameters' do
        expect(executor).to receive(:do_drop_collection).with(collection)
        expect(executor).to receive(:drop_collection_record).with(collection)

        executor.drop_collection(name)
      end
    end

    context 'when collection does not exist' do
      before do
        allow(collections).to receive(:find_by).with(name: full_name).and_return(nil)
      end

      it 'returns early without calling database-specific drop methods' do
        expect(executor).not_to receive(:do_drop_collection)
        expect(executor).not_to receive(:drop_collection_record)

        executor.drop_collection(name)
      end
    end
  end

  describe '#drop_collection_record' do
    it 'destroys the collection record' do
      expect(collection).to receive(:destroy!)

      executor.send(:drop_collection_record, collection)
    end
  end

  describe '#do_create_collection' do
    it 'raises NotImplementedError if not implemented in a subclass' do
      executor = incomplete_class.new(adapter)
      expect { executor.send(:do_create_collection, name: 'test', number_of_partitions: 1, fields: []) }
        .to raise_error(NotImplementedError)
    end
  end

  describe '#do_drop_collection' do
    it 'raises NotImplementedError if not implemented in a subclass' do
      executor = incomplete_class.new(adapter)
      expect { executor.send(:do_drop_collection, collection) }
        .to raise_error(NotImplementedError)
    end
  end
end
