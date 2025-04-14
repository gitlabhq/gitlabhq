# frozen_string_literal: true

RSpec.describe ActiveContext::BulkProcessor do
  let(:connection) { double('Connection') }
  let(:adapter) { ActiveContext::Databases::Elasticsearch::Adapter.new(connection, options: { url: 'http://localhost:9200' }) }
  let(:logger) { instance_double(Logger) }
  let(:reference_class) { Test::References::MockWithDatabaseRecord }

  let(:ref) { reference_class.new(collection_id: collection_id, routing: partition, args: 1) }
  let(:mock_collection) { double(name: collection_name, partition_for: partition) }
  let(:mock_object) { double(id: object_id) }
  let(:mock_relation) { double(find_by: mock_object) }
  let(:mock_connection) { double(id: connection_id) }

  let(:connection_id) { 3 }
  let(:partition) { 2 }
  let(:collection_id) { 1 }
  let(:object_id) { 5 }
  let(:collection_name) { 'mock_collection' }

  before do
    allow(ActiveContext).to receive(:adapter).and_return(adapter)
    allow(ActiveContext::Config).to receive(:logger).and_return(logger)
    allow(ActiveContext::CollectionCache).to receive(:fetch).and_return(mock_collection)
    allow(ActiveContext::Logger).to receive(:exception).and_return(nil)
    allow(reference_class).to receive(:model_klass).and_return(mock_relation)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
  end

  describe '#initialize' do
    it 'initializes with empty failures and the correct adapter' do
      processor = described_class.new

      expect(processor.failures).to be_empty
      expect(processor.adapter).to be_a(ActiveContext::Databases::Elasticsearch::Adapter)
    end
  end

  describe '#process' do
    let(:processor) { described_class.new }

    it 'adds ref to adapter and calls send_bulk if it returns true' do
      allow(adapter).to receive(:add_ref).and_return(true)
      expect(processor).to receive(:send_bulk).once

      processor.process(ref)
    end

    it 'adds ref to adapter and does not call send_bulk if it returns false' do
      allow(adapter).to receive(:add_ref).and_return(false)
      expect(processor).not_to receive(:send_bulk)

      processor.process(ref)
    end
  end

  describe '#flush' do
    let(:processor) { described_class.new }

    it 'calls send_bulk and returns failures' do
      allow(processor).to receive(:send_bulk).and_return(processor)
      expect(processor.flush).to eq([])
    end
  end

  describe '#send_bulk' do
    let(:processor) { described_class.new }

    before do
      processor.process(ref)
    end

    it 'processes bulk and logs info' do
      allow(adapter).to receive(:bulk).and_return([{ 'items' => [] }])

      expect(logger).to receive(:info).with(
        'message' => 'bulk_submitted',
        'meta.indexing.bulk_count' => 1,
        'meta.indexing.errors_count' => 0
      )

      processor.send(:send_bulk)
    end

    it 'resets the adapter after processing' do
      allow(adapter).to receive(:bulk).and_return([{ 'items' => [] }])
      expect(adapter).to receive(:reset)

      processor.send(:send_bulk)
    end
  end

  describe '#try_send_bulk' do
    let(:processor) { described_class.new }

    before do
      processor.process(ref)
    end

    context 'when bulk processing succeeds' do
      it 'returns empty array' do
        allow(adapter).to receive(:bulk).and_return([{ 'items' => [] }])
        expect(processor.send(:try_send_bulk)).to eq([])
      end
    end

    context 'when bulk processing fails' do
      it 'logs error and returns all refs' do
        allow(adapter).to receive(:bulk).and_raise(StandardError.new('Bulk processing failed'))

        expect(logger).to receive(:error).with(
          message: 'bulk_exception',
          error_class: 'StandardError',
          error_message: 'Bulk processing failed'
        )

        expect(processor.send(:try_send_bulk)).to eq([ref])
      end
    end
  end
end
