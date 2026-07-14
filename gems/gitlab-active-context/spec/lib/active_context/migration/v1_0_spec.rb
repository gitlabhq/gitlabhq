# frozen_string_literal: true

RSpec.describe ActiveContext::Migration::V1_0 do
  let(:migration) { described_class.new }

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
    pending 'creates a collection'
  end

  describe '#update_collection_metadata' do
    pending 'updates collection metadata'
  end

  describe '#drop_collection' do
    pending 'drops a collection'
  end

  describe '#add_field' do
    pending 'adds a field'
  end
end
