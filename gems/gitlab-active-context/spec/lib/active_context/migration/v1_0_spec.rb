# frozen_string_literal: true

RSpec.describe ActiveContext::Migration::V1_0 do
  let(:migration) { described_class.new }
  let(:mock_adapter) { double }
  let(:mock_executor) { double }

  before do
    allow(ActiveContext).to receive(:adapter).and_return(mock_adapter)
    allow(mock_adapter).to receive(:executor).and_return(mock_executor)
  end

  describe '#set_collection_class' do
    let(:collection) { Test::Collections::Mock }
    let(:collection_record) { double('CollectionRecord', metadata: metadata) }
    let(:metadata) { {} }

    before do
      allow(collection).to receive(:collection_record).and_return(collection_record)
      allow(collection_record).to receive(:update_metadata!)
    end

    context 'when collection_class is not set' do
      it 'sets the collection_class metadata' do
        migration.set_collection_class(collection)

        expect(collection_record).to have_received(:update_metadata!).with(
          collection_class: 'Test::Collections::Mock'
        )
      end
    end

    context 'when collection_class is already set' do
      let(:metadata) { { collection_class: 'Test::Collections::Mock' } }

      it 'does not update the metadata' do
        migration.set_collection_class(collection)

        expect(collection_record).not_to have_received(:update_metadata!)
      end
    end
  end

  describe '#create_collection' do
    it 'creates a collection' do
      passed_block = proc {}

      expect(mock_executor).to receive(:create_collection)
        .with('my_collection', number_of_partitions: 2) { |&block| expect(block).to equal(passed_block) }

      migration.create_collection('my_collection', number_of_partitions: 2, &passed_block)
    end
  end

  describe '#update_collection_metadata' do
    let(:collection) { Test::Collections::Mock }
    let(:collection_record) { double }

    before do
      allow(collection).to receive(:collection_record).and_return(collection_record)
      allow(collection_record).to receive(:update_metadata!)
    end

    context 'when metadata is a hash' do
      it 'updates the metadata with the collection_class merged in' do
        migration.update_collection_metadata(collection: collection, metadata: { foo: 'bar' })

        expect(collection_record).to have_received(:update_metadata!).with(
          foo: 'bar', collection_class: 'Test::Collections::Mock'
        )
      end
    end

    context 'when metadata is not a hash' do
      it 'raises a MigrationError' do
        expect do
          migration.update_collection_metadata(collection: collection, metadata: 'not a hash')
        end.to raise_error(described_class::MigrationError, 'Metadata should be a hash')
      end
    end
  end

  describe '#drop_collection' do
    it 'drops a collection' do
      expect(mock_executor).to receive(:drop_collection).with('my_collection')

      migration.drop_collection('my_collection')
    end
  end

  describe '#add_field' do
    it 'adds a field' do
      passed_block = proc {}

      expect(mock_executor).to receive(:add_field)
        .with('my_collection') { |&block| expect(block).to equal(passed_block) }

      migration.add_field('my_collection', &passed_block)
    end
  end
end
