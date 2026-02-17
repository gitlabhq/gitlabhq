# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Postgresql::Executor do
  before do
    allow(adapter).to receive(:client).and_return(client)
    allow(ActiveContext).to receive(:adapter).and_return(adapter)
  end

  let(:client) { double('Client') }
  let(:pg_connection) { double('PgConnection') }
  let(:adapter) do
    double('Adapter', connection: connection, separator: '_', full_collection_name: ->(name) {
      "prefix_#{name}"
    })
  end

  let(:connection) { double('Connection') }

  subject(:executor) { described_class.new(adapter) }

  describe '#add_field' do
    let(:collection_name) { 'test_collection' }
    let(:collection) { double('Collection', name: 'prefix_test_collection', number_of_partitions: 2) }

    before do
      allow(connection).to receive_message_chain(:collections, :find_by).and_return(collection)
      allow(client).to receive(:with_connection).and_yield(pg_connection)
      allow(pg_connection).to receive_messages(column_exists?: false, index_exists?: false)
      allow(pg_connection).to receive(:add_column)
      allow(pg_connection).to receive(:execute)
      allow(pg_connection).to receive(:quote_table_name) { |name| "\"#{name}\"" }
      allow(pg_connection).to receive(:quote_column_name) { |name| "\"#{name}\"" }
    end

    it 'adds field to main collection' do
      executor.add_field(collection_name) do |c|
        c.text(:description)
      end

      expect(pg_connection).to have_received(:add_column).with('prefix_test_collection', 'description', :text)
    end

    it 'skips adding column if it already exists' do
      allow(pg_connection).to receive(:column_exists?).and_return(true)

      executor.add_field(collection_name) do |c|
        c.text(:description)
      end

      expect(pg_connection).not_to have_received(:add_column)
      expect(pg_connection).not_to have_received(:execute)
    end

    it 'uses add_column with vector type for vector field' do
      executor.add_field(collection_name) do |c|
        c.vector(:embeddings_v2, dimensions: 768)
      end

      expect(pg_connection).to have_received(:add_column).with(
        'prefix_test_collection',
        'embeddings_v2',
        'vector(768)'
      )
    end

    context 'when collection does not exist' do
      before do
        allow(connection).to receive_message_chain(:collections, :find_by).and_return(nil)
      end

      it 'raises an error' do
        expect do
          executor.add_field(collection_name) do |c|
            c.text(:description)
          end
        end.to raise_error(/Collection .* not found/)
      end
    end

    context 'when field is reserved' do
      before do
        allow(connection).to receive_message_chain(:collections, :find_by).and_return(collection)
      end

      it 'skips reserved fields' do
        executor.add_field(collection_name) do |c|
          c.text(:id)
        end

        expect(pg_connection).not_to have_received(:add_column)
        expect(pg_connection).not_to have_received(:execute)
      end
    end
  end

  describe '#create_collection' do
    let(:collection_name) { 'test_collection' }
    let(:number_of_partitions) { 2 }
    let(:collection_record) { double('Collection', save!: true) }

    before do
      allow(connection).to receive_message_chain(:collections, :find_or_initialize_by).and_return(collection_record)
      allow(collection_record).to receive(:update)
      allow(client).to receive(:with_connection).and_yield(pg_connection)
      allow(pg_connection).to receive(:create_table)
      allow(pg_connection).to receive(:execute)
      allow(pg_connection).to receive(:add_index)
      allow(pg_connection).to receive_messages(table_exists?: false, index_exists?: false)
      allow(pg_connection).to receive(:quote_table_name) { |name| "\"#{name}\"" }
      allow(pg_connection).to receive(:quote_column_name) { |name| "\"#{name}\"" }
    end

    it 'creates collection with correct attributes' do
      executor.create_collection(collection_name, number_of_partitions: number_of_partitions) do |builder|
        builder.text(:content)
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
        builder.text(:content)
      end

      expect(collection_record).to have_received(:update).with(
        number_of_partitions: number_of_partitions,
        include_ref_fields: false
      )
    end
  end

  describe '#drop_collection' do
    let(:collection_name) { 'test_collection' }
    let(:collection) { double('Collection', name: 'prefix_test_collection', destroy!: true) }

    before do
      allow(connection).to receive_message_chain(:collections, :find_by).and_return(collection)
      allow(client).to receive(:with_connection).and_yield(pg_connection)
      allow(pg_connection).to receive(:drop_table)
    end

    it 'drops the collection table' do
      executor.drop_collection(collection_name)

      expect(pg_connection).to have_received(:drop_table).with('prefix_test_collection', if_exists: true)
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

        expect(pg_connection).not_to have_received(:drop_table)
      end
    end
  end
end
