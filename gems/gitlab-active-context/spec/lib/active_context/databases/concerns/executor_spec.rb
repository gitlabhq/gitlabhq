# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Concerns::Executor do
  let(:name) { 'test_collection' }
  let(:full_name) { 'prefixed_test_collection' }
  let(:number_of_partitions) { 5 }
  let(:fields) { [{ name: 'field1', type: 'string' }] }
  let(:mock_builder) { double('CollectionBuilder', fields: fields) }

  # Create a test class that includes the executor module
  let(:test_class) do
    Class.new do
      include ActiveContext::Databases::Concerns::Executor

      def do_create_collection(name:, number_of_partitions:, fields:, options: {})
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

  before do
    allow(ActiveContext::Databases::CollectionBuilder).to receive(:new).and_return(mock_builder)
    allow(adapter).to receive(:full_collection_name).with(name).and_return(full_name)
  end

  describe '#initialize' do
    it 'sets the adapter attribute' do
      expect(executor.adapter).to eq(adapter)
    end
  end

  describe '#create_collection' do
    before do
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

      executor.create_collection(name, number_of_partitions: number_of_partitions) do |builder|
        builder.add_field('name', 'string')
      end
    end

    context 'when not implemented in a subclass' do
      let(:executor) { incomplete_class.new(adapter) }

      before do
        allow(executor).to receive(:do_create_collection).and_call_original
        allow(executor).to receive(:create_collection_record).and_call_original
      end

      it 'raises NotImplementedError' do
        expect { executor.create_collection(name, number_of_partitions: number_of_partitions) }
          .to raise_error(NotImplementedError)
      end
    end

    context 'when persisting the collection record' do
      before do
        allow(executor).to receive(:create_collection_record).and_call_original
      end

      it 'creates or updates a collection record with the correct attributes' do
        expect(collections).to receive(:find_or_initialize_by).with(name: full_name).and_return(collection)
        expect(collection).to receive(:update)
          .with(number_of_partitions: number_of_partitions, include_ref_fields: true)
        expect(collection).to receive(:save!)

        executor.create_collection(name, number_of_partitions: number_of_partitions)
      end

      it 'sets include_ref_fields if passed in options' do
        expect(collections).to receive(:find_or_initialize_by).with(name: full_name).and_return(collection)
        expect(collection).to receive(:update)
          .with(number_of_partitions: number_of_partitions, include_ref_fields: false)
        expect(collection).to receive(:save!)

        executor.create_collection(name, number_of_partitions: number_of_partitions,
          options: { include_ref_fields: false })
      end
    end
  end

  describe '#drop_collection' do
    context 'when collection exists' do
      before do
        allow(collections).to receive(:find_by).with(name: full_name).and_return(collection)
      end

      it 'drops a collection with the correct parameters' do
        expect(executor).to receive(:do_drop_collection).with(collection)
        expect(executor).to receive(:drop_collection_record).with(collection)

        executor.drop_collection(name)
      end

      context 'when destroying the collection record' do
        before do
          allow(executor).to receive(:do_drop_collection)
        end

        it 'destroys the collection record' do
          expect(collection).to receive(:destroy!)

          executor.drop_collection(name)
        end
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

    context 'when not implemented in a subclass' do
      let(:executor) { incomplete_class.new(adapter) }

      before do
        allow(collections).to receive(:find_by).with(name: full_name).and_return(collection)
      end

      it 'raises NotImplementedError' do
        expect { executor.drop_collection(name) }
          .to raise_error(NotImplementedError)
      end
    end
  end

  describe '#add_field' do
    let(:field) { { name: 'title', type: 'string' } }

    before do
      allow(mock_builder).to receive(:add_field)
      allow(mock_builder).to receive(:fields).and_return([field])
    end

    context 'when collection exists' do
      before do
        allow(collections).to receive(:find_by).with(name: full_name).and_return(collection)
      end

      it 'calls do_add_field for each field yielded by the builder' do
        expect(executor).to receive(:do_add_field).with(collection, field)

        executor.add_field(name) { |b| b.add_field('title', 'string') }
      end

      context 'when multiple fields are added' do
        let(:another_field) { { name: 'body', type: 'text' } }

        before do
          allow(mock_builder).to receive(:fields).and_return([field, another_field])
        end

        it 'calls do_add_field for each field' do
          expect(executor).to receive(:do_add_field).with(collection, field)
          expect(executor).to receive(:do_add_field).with(collection, another_field)

          executor.add_field(name) { |b| b.add_field('title', 'string') }
        end
      end
    end

    context 'when collection does not exist' do
      before do
        allow(collections).to receive(:find_by).with(name: full_name).and_return(nil)
      end

      it 'raises an error' do
        expect do
          executor.add_field(name) { |b| b.add_field('title', 'string') }
        end.to raise_error(/Collection .* not found/)
      end
    end

    context 'when not implemented in a subclass' do
      let(:executor) { incomplete_class.new(adapter) }

      before do
        allow(collections).to receive(:find_by).with(name: full_name).and_return(collection)
      end

      it 'raises NotImplementedError' do
        expect { executor.add_field(name) { |b| b.add_field('title', 'string') } }
          .to raise_error(NotImplementedError)
      end
    end
  end

  describe '#nullify_field' do
    let(:field_name) { 'description' }

    context 'when collection exists' do
      before do
        allow(collections).to receive(:find_by).with(name: full_name).and_return(collection)
      end

      it 'calls do_nullify_field with correct parameters' do
        expect(executor).to receive(:do_nullify_field).with(collection, field_name, batch_size: 1000)

        executor.nullify_field(name, field_name, batch_size: 1000)
      end

      it 'returns the result from do_nullify_field' do
        allow(executor).to receive(:do_nullify_field).and_return(42)

        result = executor.nullify_field(name, field_name, batch_size: 1000)

        expect(result).to eq(42)
      end
    end

    context 'when collection does not exist' do
      before do
        allow(collections).to receive(:find_by).with(name: full_name).and_return(nil)
      end

      it 'raises an error' do
        expect do
          executor.nullify_field(name, field_name, batch_size: 1000)
        end.to raise_error(/Collection .* not found/)
      end
    end

    context 'when not implemented in a subclass' do
      let(:executor) { incomplete_class.new(adapter) }

      before do
        allow(collections).to receive(:find_by).with(name: full_name).and_return(collection)
      end

      it 'raises NotImplementedError' do
        expect { executor.nullify_field(name, 'field_name', batch_size: 1000) }
          .to raise_error(NotImplementedError)
      end
    end
  end
end
