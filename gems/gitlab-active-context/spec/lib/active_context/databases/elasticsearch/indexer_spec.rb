# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Elasticsearch::Indexer do
  let(:es_client) { instance_double(Elasticsearch::Client) }
  let(:logger) { instance_double(Logger, warn: nil) }
  let(:options) { {} }
  let(:indexer) { described_class.new(options, es_client) }
  let(:ref) { double }

  before do
    allow(ActiveContext::Config).to receive(:logger).and_return(logger)
    allow(ref).to receive_messages(
      operation: :index,
      id: 1,
      as_indexed_json: { title: 'Test Issue' },
      partition_name: 'issues',
      identifier: '1',
      routing: 'group_1',
      serialize: 'issue 1 group_1'
    )
  end

  describe '#initialize' do
    it 'initializes with empty operations and zero bulk size' do
      expect(indexer.operations).to be_empty
      expect(indexer.bulk_size).to eq(0)
    end
  end

  describe '#add_ref' do
    it 'adds the ref and returns true when bulk threshold is reached' do
      allow(indexer).to receive(:bulk_threshold).and_return(1)
      expect(indexer.add_ref(ref)).to be true
      expect(indexer.operations).not_to be_empty
    end

    it 'adds the ref and returns false when bulk threshold is not reached' do
      allow(indexer).to receive(:bulk_threshold).and_return(1000000)
      expect(indexer.add_ref(ref)).to be false
      expect(indexer.operations).not_to be_empty
    end

    it 'raises an error for unsupported operations' do
      allow(ref).to receive(:operation).and_return(:unsupported)
      expect { indexer.add_ref(ref) }.to raise_error(StandardError, /Operation unsupported is not supported/)
    end
  end

  describe '#empty?' do
    it 'returns true when there are no operations' do
      expect(indexer).to be_empty
    end

    it 'returns false when there are operations' do
      indexer.instance_variable_set(:@operations, [{}])
      expect(indexer).not_to be_empty
    end
  end

  describe '#bulk' do
    before do
      indexer.instance_variable_set(:@operations, [{ index: {} }])
    end

    it 'calls bulk on the client with flattened operations' do
      expect(es_client).to receive(:bulk).with(body: [{ index: {} }])
      indexer.bulk
    end
  end

  describe '#process_bulk_errors' do
    before do
      indexer.instance_variable_set(:@refs, [ref])
    end

    context 'when there are no errors' do
      it 'returns an empty array' do
        result = { 'errors' => false }
        expect(indexer.process_bulk_errors(result)).to be_empty
      end
    end

    context 'when there are errors' do
      let(:result) do
        {
          'errors' => true,
          'items' => [
            { 'index' => { 'error' => 'Error message', 'status' => 400 } }
          ]
        }
      end

      it 'logs warnings and returns failed refs' do
        expect(logger).to receive(:warn).with(
          'message' => 'indexing_failed',
          'meta.indexing.error' => 'Error message',
          'meta.indexing.status' => 400,
          'meta.indexing.operation_type' => 'index',
          'meta.indexing.ref' => 'issue 1 group_1',
          'meta.indexing.identifier' => '1'
        )

        failed_refs = indexer.process_bulk_errors(result)
        expect(failed_refs).to eq([ref])
      end
    end
  end

  describe '#reset' do
    before do
      indexer.instance_variable_set(:@operations, [{}])
      indexer.instance_variable_set(:@bulk_size, 100)
    end

    it 'resets operations and bulk size' do
      indexer.reset
      expect(indexer.operations).to be_empty
      expect(indexer.bulk_size).to eq(0)
    end
  end
end
