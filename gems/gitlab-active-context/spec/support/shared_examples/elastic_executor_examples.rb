# frozen_string_literal: true

RSpec.shared_examples 'an elastic executor' do
  let(:connection) { double('Connection') }
  let(:adapter) do
    double('Adapter', connection: connection, separator: '_', full_collection_name: ->(name) {
      "prefix_#{name}"
    })
  end

  let(:raw_client) { double('RawClient') }
  let(:indices_client) { double('IndicesClient') }
  let(:client) { double('Client', client: raw_client) }

  subject(:executor) { described_class.new(adapter) }

  before do
    allow(ActiveContext).to receive(:adapter).and_return(adapter)
    allow(adapter).to receive(:client).and_return(client)
    allow(raw_client).to receive(:indices).and_return(indices_client)
  end

  describe '#initialize' do
    it 'sets the adapter' do
      expect(executor.adapter).to eq(adapter)
    end
  end

  describe '#create_collection' do
    let(:collection_name) { 'test_collection' }
    let(:number_of_partitions) { 2 }
    let(:fields) do
      [
        ActiveContext::Databases::Field::Keyword.new(:title),
        ActiveContext::Databases::Field::Text.new(:description),
        ActiveContext::Databases::Field::Integer.new(:count)
      ]
    end

    let(:collection_record) { double('Collection', save!: true) }

    before do
      allow(connection).to receive_message_chain(:collections, :find_or_initialize_by).and_return(collection_record)
      allow(collection_record).to receive(:update)
      allow(indices_client).to receive_messages(exists?: false, exists_alias?: false)
      allow(indices_client).to receive(:create)
      allow(indices_client).to receive(:update_aliases)
    end

    it 'creates partitions and alias' do
      executor.create_collection(collection_name, number_of_partitions: number_of_partitions) do |builder|
        builder.keyword(:title)
        builder.text(:description)
        builder.integer(:count)
      end

      expect(indices_client).to have_received(:create).twice
      expect(indices_client).to have_received(:update_aliases)
    end

    it 'creates collection record with correct attributes' do
      executor.create_collection(collection_name, number_of_partitions: number_of_partitions) do |builder|
        builder.keyword(:title)
      end

      expect(collection_record).to have_received(:update).with(
        number_of_partitions: number_of_partitions,
        include_ref_fields: true
      )
      expect(collection_record).to have_received(:save!)
    end

    it 'respects include_ref_fields option' do
      executor.create_collection(collection_name, number_of_partitions: number_of_partitions,
        options: { include_ref_fields: false }) do |builder|
        builder.keyword(:title)
      end

      expect(collection_record).to have_received(:update).with(
        number_of_partitions: number_of_partitions,
        include_ref_fields: false
      )
    end

    context 'when collection already exists' do
      before do
        allow(indices_client).to receive_messages(exists?: true, exists_alias?: true)
      end

      it 'does not create partitions or alias' do
        executor.create_collection(collection_name, number_of_partitions: number_of_partitions) do |builder|
          builder.keyword(:title)
        end

        expect(indices_client).not_to have_received(:create)
        expect(indices_client).not_to have_received(:update_aliases)
      end
    end
  end

  describe '#drop_collection' do
    let(:collection_name) { 'test_collection' }
    let(:collection) { double('Collection', name: 'prefix_test_collection', number_of_partitions: 2, destroy!: true) }

    before do
      allow(connection).to receive_message_chain(:collections, :find_by).and_return(collection)
      allow(indices_client).to receive_messages(exists?: true,
        exists_alias?: true,
        get_alias: {
          'prefix_test_collection_0' => {},
          'prefix_test_collection_1' => {}
        }
      )
      allow(indices_client).to receive(:delete_alias)
      allow(indices_client).to receive(:delete)
    end

    it 'removes alias and deletes partitions' do
      executor.drop_collection(collection_name)

      expect(indices_client).to have_received(:delete_alias).twice
      expect(indices_client).to have_received(:delete).twice
    end

    it 'destroys collection record' do
      executor.drop_collection(collection_name)

      expect(collection).to have_received(:destroy!)
    end

    context 'when collection does not exist' do
      before do
        allow(connection).to receive_message_chain(:collections, :find_by).and_return(nil)
      end

      it 'does not attempt to drop anything' do
        executor.drop_collection(collection_name)

        expect(indices_client).not_to have_received(:delete_alias)
        expect(indices_client).not_to have_received(:delete)
      end
    end
  end

  describe '#mappings' do
    it 'builds mappings for all field types' do
      fields = [
        ActiveContext::Databases::Field::Bigint.new(:bigint_field),
        ActiveContext::Databases::Field::Integer.new(:integer_field),
        ActiveContext::Databases::Field::Smallint.new(:smallint_field),
        ActiveContext::Databases::Field::Boolean.new(:boolean_field),
        ActiveContext::Databases::Field::Keyword.new(:keyword_field),
        ActiveContext::Databases::Field::Text.new(:text_field)
      ]

      mappings = executor.send(:mappings, fields)

      expect(mappings).to include(
        'bigint_field' => { type: 'long' },
        'integer_field' => { type: 'integer' },
        'smallint_field' => { type: 'short' },
        'boolean_field' => { type: 'boolean' },
        'keyword_field' => { type: 'keyword' },
        'text_field' => { type: 'text' },
        ref_id: { type: 'keyword' },
        ref_version: { type: 'long' }
      )
    end

    it 'excludes ref fields when include_ref_fields is false' do
      fields = [ActiveContext::Databases::Field::Keyword.new(:title)]

      mappings = executor.send(:mappings, fields, include_ref_fields: false)

      expect(mappings).to include('title' => { type: 'keyword' })
      expect(mappings).not_to include(:ref_id, :ref_version)
    end

    it 'raises error for unknown field type' do
      unknown_field = Class.new(ActiveContext::Databases::Field).new(:unknown)
      fields = [unknown_field]

      expect { executor.send(:mappings, fields) }.to raise_error(ArgumentError, /Unknown field type/)
    end
  end

  describe '#collection_exists?' do
    let(:strategy) do
      double('PartitionStrategy', collection_name: 'test_collection',
        partition_names: %w[test_collection_0 test_collection_1])
    end

    context 'when alias and all partitions exist' do
      before do
        allow(indices_client).to receive(:exists_alias?).with(name: 'test_collection').and_return(true)
        allow(indices_client).to receive(:exists?).and_return(true)
        allow(strategy).to receive(:fully_exists?).and_yield('test_collection_0')
          .and_yield('test_collection_1').and_return(true)
      end

      it 'returns true' do
        expect(executor.send(:collection_exists?, strategy)).to be true
      end
    end

    context 'when alias does not exist' do
      before do
        allow(indices_client).to receive(:exists_alias?).with(name: 'test_collection').and_return(false)
      end

      it 'returns false' do
        expect(executor.send(:collection_exists?, strategy)).to be false
      end
    end

    context 'when some partitions are missing' do
      before do
        allow(indices_client).to receive(:exists_alias?).with(name: 'test_collection').and_return(true)
        allow(strategy).to receive(:fully_exists?).and_return(false)
      end

      it 'returns false' do
        expect(executor.send(:collection_exists?, strategy)).to be false
      end
    end
  end

  describe '#index_exists?' do
    it 'returns true when index exists' do
      allow(indices_client).to receive(:exists?).with(index: 'test_index').and_return(true)

      expect(executor.send(:index_exists?, 'test_index')).to be true
    end

    it 'returns false when index does not exist' do
      allow(indices_client).to receive(:exists?).with(index: 'test_index').and_return(false)

      expect(executor.send(:index_exists?, 'test_index')).to be false
    end
  end

  describe '#alias_exists?' do
    it 'returns true when alias exists' do
      allow(indices_client).to receive(:exists_alias?).with(name: 'test_alias').and_return(true)

      expect(executor.send(:alias_exists?, 'test_alias')).to be true
    end

    it 'returns false when alias does not exist' do
      allow(indices_client).to receive(:exists_alias?).with(name: 'test_alias').and_return(false)

      expect(executor.send(:alias_exists?, 'test_alias')).to be false
    end
  end

  describe '#create_partition' do
    let(:fields) { [ActiveContext::Databases::Field::Keyword.new(:title)] }

    it 'creates index with correct mappings and settings' do
      expect(indices_client).to receive(:create).with(
        index: 'test_partition',
        body: hash_including(
          mappings: hash_including(
            dynamic: 'strict',
            properties: hash_including('title' => { type: 'keyword' })
          ),
          settings: kind_of(Hash)
        )
      )

      executor.send(:create_partition, 'test_partition', fields)
    end
  end

  describe '#create_alias' do
    let(:strategy) do
      double('PartitionStrategy', collection_name: 'test_collection',
        partition_names: %w[test_collection_0 test_collection_1])
    end

    it 'creates alias for all partitions' do
      expect(indices_client).to receive(:update_aliases).with(
        body: {
          actions: [{
            add: {
              indices: %w[test_collection_0 test_collection_1],
              alias: 'test_collection'
            }
          }]
        }
      )

      executor.send(:create_alias, strategy)
    end
  end

  describe '#remove_alias' do
    let(:strategy) { double('PartitionStrategy', collection_name: 'test_collection') }

    it 'removes alias from all indices' do
      allow(indices_client).to receive(:get_alias).with(name: 'test_collection').and_return({
        'test_collection_0' => {},
        'test_collection_1' => {}
      })

      expect(indices_client).to receive(:delete_alias).with(index: 'test_collection_0', name: 'test_collection')
      expect(indices_client).to receive(:delete_alias).with(index: 'test_collection_1', name: 'test_collection')

      executor.send(:remove_alias, strategy)
    end
  end

  describe '#remove_index' do
    it 'deletes the index' do
      expect(indices_client).to receive(:delete).with(index: 'test_index')

      executor.send(:remove_index, 'test_index')
    end
  end
end
