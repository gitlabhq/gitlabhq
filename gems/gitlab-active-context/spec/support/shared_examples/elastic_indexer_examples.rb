# frozen_string_literal: true

RSpec.shared_examples 'an elastic indexer' do
  let(:logger) { instance_double(Logger, warn: nil) }
  let(:options) { {} }
  let(:ref) { double }

  before do
    allow(ActiveContext::Config).to receive(:logger).and_return(logger)
    allow(ref).to receive_messages(
      operation: :upsert,
      id: 1,
      partition_name: 'issues',
      identifier: '1',
      partition: 'issues_0',
      routing: 'group_1',
      serialize: 'issue 1 group_1',
      jsons: [{ title: 'Test Issue' }],
      ref_version: 123456
    )
  end

  describe '#initialize' do
    it 'initializes with empty operations and zero bulk size' do
      expect(indexer.index_operations).to be_empty
      expect(indexer.bulk_size).to eq(0)
    end
  end

  describe '#add_ref' do
    it 'adds the ref and returns true when bulk threshold is reached' do
      allow(indexer).to receive(:bulk_threshold).and_return(1)
      expect(indexer.add_ref(ref)).to be true
      expect(indexer.index_operations).not_to be_empty
    end

    it 'adds the ref and returns false when bulk threshold is not reached' do
      allow(indexer).to receive(:bulk_threshold).and_return(1000000)
      expect(indexer.add_ref(ref)).to be false
      expect(indexer.instance_variable_get(:@refs)).to include(ref)
    end

    it 'raises an error for unsupported operations' do
      allow(ref).to receive(:operation).and_return(:unsupported)
      indexer.instance_variable_set(:@refs, [ref])
      expect { indexer.send(:build_delete_operations) }
        .to raise_error(StandardError, /Operation unsupported is not supported/)
    end
  end

  describe '#empty?' do
    it 'returns true when there are no operations' do
      expect(indexer).to be_empty
    end

    it 'returns false when there are operations' do
      indexer.instance_variable_set(:@refs, [ref])
      expect(indexer).not_to be_empty
    end
  end

  describe '#bulk' do
    context 'when only index operations are present' do
      before do
        indexer.instance_variable_set(:@index_operations, [{ index: {} }])
        indexer.instance_variable_set(:@refs, [])
      end

      it 'calls bulk on the client with flattened operations' do
        expect(client).to receive(:bulk).with(body: [{ index: {} }], refresh: true)
        indexer.bulk
      end
    end

    context 'when delete operations are present' do
      let(:delete_ref) { double }

      before do
        indexer.instance_variable_set(:@index_operations, [])

        allow(delete_ref).to receive_messages(
          operation: :delete,
          identifier: '1',
          partition: 'issues_0'
        )

        indexer.instance_variable_set(:@refs, [delete_ref])
      end

      it 'calls delete_by_query on the client with the correct parameters' do
        expect(client).to receive(:delete_by_query).with(
          hash_including(
            index: 'issues_0',
            body: hash_including(
              query: hash_including(
                bool: hash_including(
                  should: array_including(
                    hash_including(terms: hash_including(ref_id: ['1']))
                  ),
                  minimum_should_match: 1
                )
              )
            )
          )
        )

        indexer.bulk
      end
    end

    context 'when both index and delete operations are present' do
      let(:delete_ref) { double }

      before do
        indexer.instance_variable_set(:@index_operations, [{ index: {} }])

        allow(delete_ref).to receive_messages(
          operation: :delete,
          identifier: '1',
          partition: 'issues_0'
        )

        indexer.instance_variable_set(:@refs, [delete_ref])
      end

      it 'calls both bulk and delete_by_query on the client' do
        expect(client).to receive(:bulk).with(body: [{ index: {} }], refresh: true)

        expect(client).to receive(:delete_by_query).with(
          hash_including(
            index: 'issues_0',
            body: hash_including(
              query: hash_including(
                bool: hash_including(
                  should: array_including(
                    hash_including(terms: hash_including(ref_id: ['1']))
                  ),
                  minimum_should_match: 1
                )
              )
            )
          )
        )

        indexer.bulk
      end
    end
  end

  describe '#process_bulk_errors' do
    before do
      indexer.instance_variable_set(:@refs, [ref])
    end

    context 'when there are no errors' do
      it 'returns an empty array' do
        result = [{ 'errors' => false }]
        expect(indexer.process_bulk_errors(result)).to be_empty
      end
    end

    context 'when there are errors' do
      let(:result) do
        [{
          'errors' => true,
          'items' => [
            { 'index' => { '_id' => '1:0', 'error' => 'Error message', 'status' => 400 } }
          ]
        }]
      end

      it 'logs warnings and returns failed refs' do
        allow(indexer).to receive(:extract_identifier).with(nil).and_return(nil)
        allow(indexer).to receive(:extract_identifier).with('1:0').and_return('1')

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
      indexer.instance_variable_set(:@index_operations, [{}])
      indexer.instance_variable_set(:@refs, [ref])
      indexer.instance_variable_set(:@bulk_size, 100)
    end

    it 'resets operations and bulk size' do
      indexer.reset
      expect(indexer.index_operations).to be_empty
      expect(indexer.instance_variable_get(:@refs)).to be_empty
      expect(indexer.bulk_size).to eq(0)
    end
  end

  describe '#build_delete_operations' do
    context 'when operation is :upsert' do
      before do
        allow(ref).to receive(:operation).and_return(:upsert)
        indexer.instance_variable_set(:@refs, [ref])
      end

      it 'creates delete operations with version query' do
        delete_ops = indexer.send(:build_delete_operations)

        expect(delete_ops.first[:index]).to eq('issues_0')
        expect(delete_ops.first[:body][:query][:bool][:should].first[:bool]).to be_present
        expect(delete_ops.first[:body][:query][:bool][:minimum_should_match]).to eq(1)
      end
    end

    context 'when operation is :delete' do
      let(:delete_ref) { double }

      before do
        allow(delete_ref).to receive_messages(
          operation: :delete,
          identifier: '1',
          partition: 'issues_0'
        )

        indexer.instance_variable_set(:@refs, [delete_ref])
      end

      it 'creates delete operations with terms query' do
        delete_ops = indexer.send(:build_delete_operations)

        expect(delete_ops.first[:index]).to eq('issues_0')
        expect(delete_ops.first[:body][:query][:bool][:should].first[:terms]).to be_present
        expect(delete_ops.first[:body][:query][:bool][:minimum_should_match]).to eq(1)
      end
    end
  end

  describe '#build_index_operations' do
    it 'adds index operations for upsert' do
      indexer.instance_variable_set(:@index_operations, [])
      indexer.instance_variable_set(:@bulk_size, 0)

      allow(ref).to receive(:operation).and_return(:upsert)
      indexer.send(:build_index_operations, ref)

      expect(indexer.index_operations).not_to be_empty
      expect(indexer.bulk_size).to be > 0
    end
  end
end
